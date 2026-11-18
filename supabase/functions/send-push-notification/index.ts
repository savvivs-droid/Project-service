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
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY — ключи push для веб-версии
//   (браузерные подписки в device_tokens с platform = 'web').
//
// SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY Supabase подставляет каждой
// Edge Function автоматически — задавать вручную не нужно.

// jsr-версия — нативная для Deno; npm-версия тянет Node-полифилы, на
// которых Edge Runtime падал с "ERR_NOT_IMPLEMENTED: callTimeout".
import { createClient } from "jsr:@supabase/supabase-js@2";
// ---------------------------------------------------------------------------
// FCM HTTP v1 на чистом fetch + WebCrypto — без firebase-admin: его
// Node-зависимости (http2 и т. п.) в Deno Edge Functions падают с
// "event loop error: ERR_NOT_IMPLEMENTED: callTimeout" и роняют функцию.
// Секрет: FIREBASE_SERVICE_ACCOUNT_KEY — JSON сервисного аккаунта Firebase.
// ---------------------------------------------------------------------------

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let serviceAccount: ServiceAccount | null = null;
function getServiceAccount(): ServiceAccount | null {
  if (serviceAccount) return serviceAccount;
  const json = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!json) return null;
  serviceAccount = JSON.parse(json) as ServiceAccount;
  return serviceAccount;
}

function base64UrlFromBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlFromString(text: string): string {
  return base64UrlFromBytes(new TextEncoder().encode(text));
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getFcmAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) {
    return cachedAccessToken.token;
  }

  const pem = account.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der as BufferSource,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const unsigned = `${base64UrlFromString(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${
    base64UrlFromString(JSON.stringify({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }))
  }`;
  const signature = new Uint8Array(await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned) as BufferSource,
  ));

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64UrlFromBytes(signature)}`,
    }),
  });
  if (!response.ok) {
    throw new Error(`FCM token request failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json() as { access_token: string; expires_in: number };
  cachedAccessToken = { token: json.access_token, expiresAt: now + json.expires_in };
  return json.access_token;
}

interface FcmResult {
  success: boolean;
  error?: { code: string };
}

/// Шлёт одно и то же уведомление на несколько FCM-токенов (Android/iOS).
/// Ответ в той же форме, что был у firebase-admin sendEachForMulticast.
async function sendFcmMulticast(message: {
  tokens: string[];
  notification: { title: string; body: string };
  data: Record<string, string>;
}): Promise<{ successCount: number; failureCount: number; responses: FcmResult[] }> {
  const account = getServiceAccount();
  if (!account) {
    console.error("FIREBASE_SERVICE_ACCOUNT_KEY secret is not set");
    return {
      successCount: 0,
      failureCount: message.tokens.length,
      responses: message.tokens.map(() => ({ success: false, error: { code: "no-credentials" } })),
    };
  }

  let accessToken: string;
  try {
    accessToken = await getFcmAccessToken(account);
  } catch (error) {
    console.error("FCM auth error", error);
    return {
      successCount: 0,
      failureCount: message.tokens.length,
      responses: message.tokens.map(() => ({ success: false, error: { code: "auth-failed" } })),
    };
  }

  const responses: FcmResult[] = [];
  for (const token of message.tokens) {
    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: message.notification,
              data: message.data,
              android: { priority: "high" },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );
      if (response.ok) {
        responses.push({ success: true });
        continue;
      }
      const text = await response.text();
      // Токен больше не действует (приложение удалено, выход и т. п.).
      const unregistered = response.status === 404 || text.includes("UNREGISTERED");
      if (!unregistered) console.error("FCM send failed", response.status, text);
      responses.push({
        success: false,
        error: {
          code: unregistered
            ? "messaging/registration-token-not-registered"
            : `http-${response.status}`,
        },
      });
    } catch (error) {
      console.error("FCM send error", error);
      responses.push({ success: false, error: { code: "network" } });
    }
  }

  const successCount = responses.filter((r) => r.success).length;
  return { successCount, failureCount: responses.length - successCount, responses };
}


// ---------------------------------------------------------------------------
// Web Push (RFC 8291 шифрование + RFC 8292 VAPID) на чистом WebCrypto — без
// внешних библиотек. Нужны секреты VAPID_PUBLIC_KEY и VAPID_PRIVATE_KEY
// (base64url, см. README) и необязательный VAPID_SUBJECT.
// ---------------------------------------------------------------------------

const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY") ?? "";
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY") ?? "";
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") ??
  "https://savvivs-droid.github.io/Project-service/";

interface WebPushSubscription {
  endpoint: string;
  keys: { p256dh: string; auth: string };
}

function b64urlDecode(value: string): Uint8Array {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/") +
    "===".slice((value.length + 3) % 4);
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function b64urlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function concatBytes(...parts: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(parts.reduce((sum, p) => sum + p.length, 0));
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

async function hmacSha256(key: Uint8Array, data: Uint8Array): Promise<Uint8Array> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw", key as BufferSource, { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  return new Uint8Array(await crypto.subtle.sign("HMAC", cryptoKey, data as BufferSource));
}

const textEncoder = new TextEncoder();

let vapidSigningKey: Promise<CryptoKey> | null = null;
function getVapidSigningKey(): Promise<CryptoKey> {
  if (!vapidSigningKey) {
    const publicRaw = b64urlDecode(VAPID_PUBLIC_KEY);
    vapidSigningKey = crypto.subtle.importKey(
      "jwk",
      {
        kty: "EC",
        crv: "P-256",
        x: b64urlEncode(publicRaw.slice(1, 33)),
        y: b64urlEncode(publicRaw.slice(33, 65)),
        d: VAPID_PRIVATE_KEY,
        ext: true,
      },
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );
  }
  return vapidSigningKey;
}

async function vapidAuthorization(endpoint: string): Promise<string> {
  const header = b64urlEncode(textEncoder.encode(JSON.stringify({ typ: "JWT", alg: "ES256" })));
  const claims = b64urlEncode(textEncoder.encode(JSON.stringify({
    aud: new URL(endpoint).origin,
    exp: Math.floor(Date.now() / 1000) + 12 * 60 * 60,
    sub: VAPID_SUBJECT,
  })));
  const unsigned = `${header}.${claims}`;
  const signature = new Uint8Array(await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    await getVapidSigningKey(),
    textEncoder.encode(unsigned) as BufferSource,
  ));
  return `vapid t=${unsigned}.${b64urlEncode(signature)}, k=${VAPID_PUBLIC_KEY}`;
}

/// Шифрует payload для подписки (RFC 8291, aes128gcm).
async function encryptPayload(
  subscription: WebPushSubscription,
  payload: Uint8Array,
): Promise<Uint8Array> {
  const uaPublic = b64urlDecode(subscription.keys.p256dh);
  const authSecret = b64urlDecode(subscription.keys.auth);

  const asKeys = await crypto.subtle.generateKey(
    { name: "ECDH", namedCurve: "P-256" }, true, ["deriveBits"],
  ) as CryptoKeyPair;
  const asPublic = new Uint8Array(await crypto.subtle.exportKey("raw", asKeys.publicKey));
  const uaKey = await crypto.subtle.importKey(
    "raw", uaPublic as BufferSource, { name: "ECDH", namedCurve: "P-256" }, false, [],
  );
  const ecdhSecret = new Uint8Array(await crypto.subtle.deriveBits(
    { name: "ECDH", public: uaKey }, asKeys.privateKey, 256,
  ));

  const prkKey = await hmacSha256(authSecret, ecdhSecret);
  const keyInfo = concatBytes(
    textEncoder.encode("WebPush: info\0"), uaPublic, asPublic, new Uint8Array([1]),
  );
  const ikm = await hmacSha256(prkKey, keyInfo);

  const salt = crypto.getRandomValues(new Uint8Array(16));
  const prk = await hmacSha256(salt, ikm);
  const cek = (await hmacSha256(
    prk, concatBytes(textEncoder.encode("Content-Encoding: aes128gcm\0"), new Uint8Array([1])),
  )).slice(0, 16);
  const nonce = (await hmacSha256(
    prk, concatBytes(textEncoder.encode("Content-Encoding: nonce\0"), new Uint8Array([1])),
  )).slice(0, 12);

  const aesKey = await crypto.subtle.importKey("raw", cek as BufferSource, "AES-GCM", false, ["encrypt"]);
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: nonce as BufferSource },
    aesKey,
    concatBytes(payload, new Uint8Array([2])) as BufferSource,
  ));

  const header = new Uint8Array(16 + 4 + 1);
  header.set(salt, 0);
  new DataView(header.buffer).setUint32(16, 4096);
  header[20] = asPublic.length;
  return concatBytes(header, asPublic, ciphertext);
}

/// Отправляет push в браузер. Возвращает "ok", "gone" (подписка больше
/// не действует — токен надо удалить) или "failed".
async function sendWebPush(
  subscriptionJson: string,
  message: Record<string, string>,
): Promise<"ok" | "gone" | "failed"> {
  if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) {
    console.error("VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY secrets are not set");
    return "failed";
  }
  try {
    const subscription = JSON.parse(subscriptionJson) as WebPushSubscription;
    const body = await encryptPayload(
      subscription, textEncoder.encode(JSON.stringify(message)),
    );
    const response = await fetch(subscription.endpoint, {
      method: "POST",
      headers: {
        Authorization: await vapidAuthorization(subscription.endpoint),
        "Content-Encoding": "aes128gcm",
        "Content-Type": "application/octet-stream",
        TTL: "86400",
        Urgency: "high",
      },
      body: body as BodyInit,
    });
    if (response.status === 404 || response.status === 410) {
      console.log("web push: subscription gone", response.status);
      return "gone";
    }
    if (!response.ok) {
      console.error("web push failed", response.status, await response.text());
      return "failed";
    }
    console.log("web push sent", response.status, new URL(subscription.endpoint).host);
    return "ok";
  } catch (error) {
    console.error("web push error", error);
    return "failed";
  }
}



const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
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
    .select("token, platform")
    .in("profile_id", recipientIds);

  if (tokensError) {
    console.error("device_tokens lookup failed", tokensError);
    return new Response("device_tokens lookup failed", { status: 200 });
  }

  const rows = tokenRows ?? [];
  if (rows.length === 0) {
    return new Response("no device tokens", { status: 200 });
  }

  const establishmentName =
    (request as unknown as { establishments: { name: string } | null })
      .establishments?.name ?? "FixMyGastro";
  const body = truncate(message.body, 120);

  // Телефоны (Android/iOS) — через FCM, браузеры (веб-версия) — Web Push.
  const tokens = rows.filter((r) => r.platform !== "web").map((r) => r.token);
  const webTokens = rows.filter((r) => r.platform === "web").map((r) => r.token);
  const staleTokens: string[] = [];
  let sent = 0;
  let failed = 0;

  if (tokens.length > 0) {
    const response = await sendFcmMulticast({
      tokens,
      notification: { title: establishmentName, body },
      data: {
        requestId: message.request_id,
        title: establishmentName,
        otherPartyName: sender.full_name ?? establishmentName,
      },
    });
    sent += response.successCount;
    failed += response.failureCount;
    // Токен мог протухнуть (переустановка приложения, выход и т. п.) —
    // подчищаем, иначе накопим мёртвые токены и будем зря слать на них.
    response.responses.forEach((result, index) => {
      if (
        !result.success &&
        result.error?.code === "messaging/registration-token-not-registered"
      ) {
        staleTokens.push(tokens[index]);
      }
    });
  }

  for (const token of webTokens) {
    const result = await sendWebPush(token, {
      title: establishmentName,
      body,
      requestId: message.request_id,
      type: "chat",
    });
    if (result === "ok") sent++;
    else failed++;
    if (result === "gone") staleTokens.push(token);
  }

  if (staleTokens.length > 0) {
    await supabase.from("device_tokens").delete().in("token", staleTokens);
  }

  console.log("chat push result", { recipients: rows.length, sent, failed });
  return new Response(
    JSON.stringify({ sent, failed }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
