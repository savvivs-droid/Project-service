// Edge Function: push-уведомления (Firebase Cloud Messaging) по заявкам.
//
//   - Новая заявка (INSERT) -> всем администраторам: какое заведение
//     и что случилось.
//   - Смена статуса (UPDATE) -> клиенту заявки: назначен или перенесён
//     визит мастера, заявка выполнена или отменена сервисом.
//
// Вызывается одним Database Webhook'ом на INSERT и UPDATE в
// public.service_requests (Supabase Dashboard -> Database -> Webhooks,
// тип "Supabase Edge Functions"). UPDATE приходит на любое изменение
// (комментарий мастера, стоимость и т. п.) — лишние случаи функция
// отсеивает сама, сравнивая record и old_record.
//
// Секреты — те же, что у send-push-notification:
//   FIREBASE_SERVICE_ACCOUNT_KEY — JSON сервисного аккаунта Firebase.
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY — ключи push для веб-версии.
// SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY подставляются автоматически.

import { createClient } from "npm:@supabase/supabase-js@2";
import { cert, getApps, initializeApp } from "npm:firebase-admin@12/app";
import { getMessaging } from "npm:firebase-admin@12/messaging";

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
    if (response.status === 404 || response.status === 410) return "gone";
    if (!response.ok) {
      console.error("web push failed", response.status, await response.text());
      return "failed";
    }
    return "ok";
  } catch (error) {
    console.error("web push error", error);
    return "failed";
  }
}


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

// Текст пуша администратору о новой заявке — в начале тело описания
// проблемы от клиента, обрезанное до разумной длины.
const NEW_REQUEST_TEXT: Record<Locale, (description: string) => string> = {
  cs: (d) => `Nový požadavek: ${d}`,
  en: (d) => `New request: ${d}`,
  ru: (d) => `Новая заявка: ${d}`,
  vi: (d) => `Yêu cầu mới: ${d}`,
};

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
  description: string;
  status: "new" | "scheduled" | "done" | "cancelled";
  scheduled_at: string | null;
  status_changed_by: string | null;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE";
  table: string;
  record: ServiceRequestRow;
  old_record: ServiceRequestRow | null;
}

function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1)}…`;
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

interface TokenRow {
  token: string;
  locale: string | null;
  platform: string;
}

/// Шлёт по одному multicast на каждый язык (у каждого устройства свой
/// язык приложения) и подчищает протухшие токены.
async function sendLocalized(
  tokenRows: TokenRow[],
  title: string,
  bodyFor: (locale: Locale) => string,
  data: Record<string, string>,
): Promise<{ sent: number; failed: number }> {
  const rowsByLocale = new Map<Locale, TokenRow[]>();
  for (const row of tokenRows) {
    const locale = normalizeLocale(row.locale);
    rowsByLocale.set(locale, [...(rowsByLocale.get(locale) ?? []), row]);
  }

  let sent = 0;
  let failed = 0;
  const staleTokens: string[] = [];

  for (const [locale, rows] of rowsByLocale) {
    const body = bodyFor(locale);

    // Телефоны (Android/iOS) — через FCM.
    const tokens = rows.filter((r) => r.platform !== "web").map((r) => r.token);
    if (tokens.length > 0) {
      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
      });
      sent += response.successCount;
      failed += response.failureCount;
      response.responses.forEach((result, index) => {
        // Токен мог протухнуть (переустановка приложения, выход и т. п.).
        if (
          !result.success &&
          result.error?.code === "messaging/registration-token-not-registered"
        ) {
          staleTokens.push(tokens[index]);
        }
      });
    }

    // Браузеры (веб-версия) — Web Push.
    for (const row of rows.filter((r) => r.platform === "web")) {
      const result = await sendWebPush(row.token, { title, body, ...data });
      if (result === "ok") sent++;
      else failed++;
      if (result === "gone") staleTokens.push(row.token);
    }
  }

  if (staleTokens.length > 0) {
    await supabase.from("device_tokens").delete().in("token", staleTokens);
  }
  return { sent, failed };
}

async function establishmentName(establishmentId: string): Promise<string> {
  const { data } = await supabase
    .from("establishments")
    .select("name")
    .eq("id", establishmentId)
    .single();
  return data?.name ?? "FixMyGastro";
}

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

async function notifyAdminsAboutNewRequest(
  record: ServiceRequestRow,
): Promise<Response> {
  const { data: admins, error: adminsError } = await supabase
    .from("profiles")
    .select("id")
    .eq("role", "admin");
  if (adminsError) {
    console.error("admins lookup failed", adminsError);
    return new Response("admins lookup failed", { status: 200 });
  }
  const adminIds = (admins ?? []).map((a) => a.id);
  if (adminIds.length === 0) {
    return new Response("no admins", { status: 200 });
  }

  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, locale, platform")
    .in("profile_id", adminIds);
  if (tokensError) {
    console.error("device_tokens lookup failed", tokensError);
    return new Response("device_tokens lookup failed", { status: 200 });
  }
  if (!tokenRows || tokenRows.length === 0) {
    return new Response("no device tokens", { status: 200 });
  }

  const description = truncate(record.description.trim(), 100);
  const result = await sendLocalized(
    tokenRows,
    await establishmentName(record.establishment_id),
    (locale) => NEW_REQUEST_TEXT[locale](description),
    { type: "new_request", requestId: record.id },
  );
  return json({ event: "new_request", ...result });
}

async function notifyClientAboutStatus(
  record: ServiceRequestRow,
  old: ServiceRequestRow,
): Promise<Response> {
  const event = detectEvent(record, old);
  if (!event) {
    return new Response("nothing to notify", { status: 200 });
  }

  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, locale, platform")
    .eq("profile_id", record.client_id);
  if (tokensError) {
    console.error("device_tokens lookup failed", tokensError);
    return new Response("device_tokens lookup failed", { status: 200 });
  }
  if (!tokenRows || tokenRows.length === 0) {
    return new Response("no device tokens", { status: 200 });
  }

  const result = await sendLocalized(
    tokenRows,
    await establishmentName(record.establishment_id),
    (locale) => TEXTS[locale][event](formatVisitTime(record.scheduled_at, locale)),
    { type: "status", requestId: record.id },
  );
  return json({ event, ...result });
}

Deno.serve(async (req) => {
  const payload = (await req.json()) as WebhookPayload;
  const { record, old_record: old } = payload;
  if (!record) return new Response("no record", { status: 200 });

  if (payload.type === "INSERT") {
    return notifyAdminsAboutNewRequest(record);
  }
  if (payload.type === "UPDATE" && old) {
    return notifyClientAboutStatus(record, old);
  }
  return new Response("ignored", { status: 200 });
});
