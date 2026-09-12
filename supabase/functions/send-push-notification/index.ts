// Edge Function: отправляет push-уведомление (Firebase Cloud Messaging)
// получателю нового сообщения в чате заявки.
//
// Вызывается Database Webhook'ом на INSERT в public.request_messages
// (настраивается в Supabase Dashboard -> Database -> Webhooks, тип
// триггера "Supabase Edge Functions" — он сам подставляет корректную
// авторизацию для вызова функции).
//
// Секреты, которые нужно задать заранее (Dashboard -> Edge Functions ->
// Secrets, или `supabase secrets set`):
//   FIREBASE_SERVICE_ACCOUNT_KEY — содержимое JSON-файла сервисного
//   аккаунта Firebase целиком (Firebase Console -> Project settings ->
//   Service accounts -> Generate new private key).
//
// SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY Supabase подставляет каждой
// Edge Function автоматически — задавать вручную не нужно.

import { createClient } from "npm:@supabase/supabase-js@2";
import { cert, getApps, initializeApp } from "npm:firebase-admin@12/app";
import { getMessaging } from "npm:firebase-admin@12/messaging";

const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
if (!serviceAccountJson) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY secret is not set");
}

// getApps() — чтобы не переинициализировать Firebase Admin SDK на каждый
// вызов: Edge Function может переиспользовать "тёплый" инстанс.
if (getApps().length === 0) {
  initializeApp({ credential: cert(JSON.parse(serviceAccountJson)) });
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

interface RequestMessageRow {
  id: string;
  request_id: string;
  sender_id: string;
  body: string;
  created_at: string;
}

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: RequestMessageRow;
}

function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1)}…`;
}

Deno.serve(async (req) => {
  const payload = (await req.json()) as WebhookPayload;
  const message = payload.record;

  // Заявка + заведение (для заголовка уведомления) и клиент заявки
  // (получатель, если пишет админ).
  const { data: request, error: requestError } = await supabase
    .from("service_requests")
    .select("client_id, establishments(name)")
    .eq("id", message.request_id)
    .single();

  if (requestError || !request) {
    console.error("service_requests lookup failed", requestError);
    return new Response("request not found", { status: 200 });
  }

  const { data: sender, error: senderError } = await supabase
    .from("profiles")
    .select("full_name, role")
    .eq("id", message.sender_id)
    .single();

  if (senderError || !sender) {
    console.error("sender profile lookup failed", senderError);
    return new Response("sender not found", { status: 200 });
  }

  // Пишет клиент -> получают все админы (любой может взять заявку в
  // работу). Пишет админ -> получает клиент, создавший заявку.
  let recipientIds: string[];
  if (sender.role === "admin") {
    recipientIds = [request.client_id];
  } else {
    const { data: admins, error: adminsError } = await supabase
      .from("profiles")
      .select("id")
      .eq("role", "admin");
    if (adminsError) {
      console.error("admins lookup failed", adminsError);
      return new Response("admins lookup failed", { status: 200 });
    }
    recipientIds = (admins ?? []).map((a) => a.id);
  }
  recipientIds = recipientIds.filter((id) => id !== message.sender_id);

  if (recipientIds.length === 0) {
    return new Response("no recipients", { status: 200 });
  }

  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token")
    .in("profile_id", recipientIds);

  if (tokensError) {
    console.error("device_tokens lookup failed", tokensError);
    return new Response("device_tokens lookup failed", { status: 200 });
  }

  const tokens = (tokenRows ?? []).map((row) => row.token);
  if (tokens.length === 0) {
    return new Response("no device tokens", { status: 200 });
  }

  const establishmentName =
    (request as unknown as { establishments: { name: string } | null })
      .establishments?.name ?? "FixMyGastro";

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: establishmentName,
      body: truncate(message.body, 120),
    },
    data: {
      requestId: message.request_id,
      title: establishmentName,
      otherPartyName: sender.full_name ?? establishmentName,
    },
  });

  // Токен мог протухнуть (переустановка приложения, выход и т. п.) —
  // подчищаем, иначе накопим мёртвые токены и будем зря слать на них.
  const staleTokens: string[] = [];
  response.responses.forEach((result, index) => {
    if (
      !result.success &&
      result.error?.code === "messaging/registration-token-not-registered"
    ) {
      staleTokens.push(tokens[index]);
    }
  });
  if (staleTokens.length > 0) {
    await supabase.from("device_tokens").delete().in("token", staleTokens);
  }

  return new Response(
    JSON.stringify({
      sent: response.successCount,
      failed: response.failureCount,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
