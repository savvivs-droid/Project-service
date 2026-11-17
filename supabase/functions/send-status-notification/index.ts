// Edge Function: отправляет клиенту push-уведомление (Firebase Cloud
// Messaging), когда меняется статус его заявки: назначен или перенесён
// визит мастера, заявка выполнена или отменена сервисом.
//
// Вызывается Database Webhook'ом на UPDATE в public.service_requests
// (Supabase Dashboard -> Database -> Webhooks, тип "Supabase Edge
// Functions"). Вебхук срабатывает на любой UPDATE (комментарий мастера,
// стоимость и т. п.) — лишние случаи функция отсеивает сама, сравнивая
// record и old_record.
//
// Секреты — те же, что у send-push-notification:
//   FIREBASE_SERVICE_ACCOUNT_KEY — JSON сервисного аккаунта Firebase.
// SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY подставляются автоматически.

import { createClient } from "npm:@supabase/supabase-js@2";
import { cert, getApps, initializeApp } from "npm:firebase-admin@12/app";
import { getMessaging } from "npm:firebase-admin@12/messaging";

const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
if (!serviceAccountJson) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY secret is not set");
}

if (getApps().length === 0) {
  initializeApp({ credential: cert(JSON.parse(serviceAccountJson)) });
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Время визита показываем по часовому поясу сервиса, а не сервера
// (Edge Functions работают в UTC).
const SERVICE_TIME_ZONE = "Europe/Prague";

type Locale = "cs" | "en" | "ru" | "vi";
const SUPPORTED_LOCALES: Locale[] = ["cs", "en", "ru", "vi"];
const DEFAULT_LOCALE: Locale = "cs";

type Event = "scheduled" | "rescheduled" | "done" | "cancelled";

const TEXTS: Record<Locale, Record<Event, (time: string) => string>> = {
  cs: {
    scheduled: (t) => `Návštěva technika naplánována: ${t}`,
    rescheduled: (t) => `Návštěva technika přesunuta: ${t}`,
    done: () => "Oprava dokončena. Děkujeme!",
    cancelled: () => "Požadavek byl zrušen servisem",
  },
  en: {
    scheduled: (t) => `Technician visit scheduled: ${t}`,
    rescheduled: (t) => `Technician visit rescheduled: ${t}`,
    done: () => "Repair completed. Thank you!",
    cancelled: () => "Your request was cancelled by the service",
  },
  ru: {
    scheduled: (t) => `Визит мастера назначен: ${t}`,
    rescheduled: (t) => `Визит мастера перенесён: ${t}`,
    done: () => "Ремонт выполнен. Спасибо!",
    cancelled: () => "Заявка отменена сервисом",
  },
  vi: {
    scheduled: (t) => `Đã hẹn lịch kỹ thuật viên: ${t}`,
    rescheduled: (t) => `Đã dời lịch kỹ thuật viên: ${t}`,
    done: () => "Đã sửa xong. Cảm ơn bạn!",
    cancelled: () => "Yêu cầu đã bị dịch vụ hủy",
  },
};

interface ServiceRequestRow {
  id: string;
  establishment_id: string;
  client_id: string;
  status: "new" | "scheduled" | "done" | "cancelled";
  scheduled_at: string | null;
  status_changed_by: string | null;
}

interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: ServiceRequestRow;
  old_record: ServiceRequestRow;
}

function detectEvent(
  record: ServiceRequestRow,
  old: ServiceRequestRow,
): Event | null {
  const statusChanged = record.status !== old.status;

  if (record.status === "scheduled") {
    if (statusChanged) return "scheduled";
    if (record.scheduled_at !== old.scheduled_at) return "rescheduled";
    return null;
  }
  if (!statusChanged) return null;
  if (record.status === "done") return "done";
  if (record.status === "cancelled") {
    // Клиент отменил сам — уведомлять его же незачем.
    if (record.status_changed_by === record.client_id) return null;
    return "cancelled";
  }
  return null;
}

function normalizeLocale(value: string | null): Locale {
  const code = (value ?? "").toLowerCase().slice(0, 2) as Locale;
  return SUPPORTED_LOCALES.includes(code) ? code : DEFAULT_LOCALE;
}

function formatVisitTime(iso: string | null, locale: Locale): string {
  if (!iso) return "";
  return new Intl.DateTimeFormat(locale, {
    timeZone: SERVICE_TIME_ZONE,
    weekday: "short",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
}

Deno.serve(async (req) => {
  const payload = (await req.json()) as WebhookPayload;
  const { record, old_record: old } = payload;
  if (!record || !old) {
    return new Response("not an update", { status: 200 });
  }

  const event = detectEvent(record, old);
  if (!event) {
    return new Response("nothing to notify", { status: 200 });
  }

  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, locale")
    .eq("profile_id", record.client_id);

  if (tokensError) {
    console.error("device_tokens lookup failed", tokensError);
    return new Response("device_tokens lookup failed", { status: 200 });
  }
  if (!tokenRows || tokenRows.length === 0) {
    return new Response("no device tokens", { status: 200 });
  }

  const { data: establishment } = await supabase
    .from("establishments")
    .select("name")
    .eq("id", record.establishment_id)
    .single();
  const title = establishment?.name ?? "FixMyGastro";

  // У каждого устройства свой язык — группируем токены по языку и шлём
  // одним multicast на группу.
  const tokensByLocale = new Map<Locale, string[]>();
  for (const row of tokenRows) {
    const locale = normalizeLocale(row.locale);
    tokensByLocale.set(locale, [...(tokensByLocale.get(locale) ?? []), row.token]);
  }

  let sent = 0;
  let failed = 0;
  const staleTokens: string[] = [];

  for (const [locale, tokens] of tokensByLocale) {
    const body = TEXTS[locale][event](formatVisitTime(record.scheduled_at, locale));
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type: "status", requestId: record.id },
    });
    sent += response.successCount;
    failed += response.failureCount;
    response.responses.forEach((result, index) => {
      if (
        !result.success &&
        result.error?.code === "messaging/registration-token-not-registered"
      ) {
        staleTokens.push(tokens[index]);
      }
    });
  }

  if (staleTokens.length > 0) {
    await supabase.from("device_tokens").delete().in("token", staleTokens);
  }

  return new Response(JSON.stringify({ event, sent, failed }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
