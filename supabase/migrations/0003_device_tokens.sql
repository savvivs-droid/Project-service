-- =============================================================================
-- Миграция: токены устройств для push-уведомлений (Firebase Cloud Messaging).
--
-- Точечный патч поверх уже работающей базы (не повторный прогон
-- schema.sql). Как применить: Supabase Dashboard -> SQL Editor ->
-- New query -> вставить весь файл -> Run. Один раз.
--
-- После этого ещё нужно (см. инструкцию от Claude отдельно):
--   1. Задеплоить Edge Function send-push-notification.
--   2. Создать Database Webhook: INSERT на public.request_messages ->
--      вызов этой функции.
-- =============================================================================

create table if not exists public.device_tokens (
  token text primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null,
  updated_at timestamptz not null default now()
);

create index if not exists idx_device_tokens_profile
  on public.device_tokens (profile_id);

alter table public.device_tokens enable row level security;

drop policy if exists "Каждый видит только свои токены устройств" on public.device_tokens;
create policy "Каждый видит только свои токены устройств"
  on public.device_tokens for select
  using (profile_id = auth.uid());

drop policy if exists "Заводит токен только от своего имени" on public.device_tokens;
create policy "Заводит токен только от своего имени"
  on public.device_tokens for insert
  with check (profile_id = auth.uid());

drop policy if exists "Обновляет только свой токен" on public.device_tokens;
create policy "Обновляет только свой токен"
  on public.device_tokens for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists "Удаляет только свой токен" on public.device_tokens;
create policy "Удаляет только свой токен"
  on public.device_tokens for delete
  using (profile_id = auth.uid());
