-- =============================================================================
-- Миграция: push-уведомления клиенту о смене статуса заявки.
--
-- Точечный патч поверх уже работающей базы (не повторный прогон
-- schema.sql). Как применить: Supabase Dashboard -> SQL Editor ->
-- New query -> вставить весь файл -> Run. Один раз.
--
-- После этого ещё нужно (см. README, раздел "Push-уведомления"):
--   1. Задеплоить Edge Function send-status-notification.
--   2. Создать Database Webhook: UPDATE на public.service_requests ->
--      вызов этой функции.
-- =============================================================================

-- 1. Язык уведомлений. Текст пуша о статусе собирает сервер, а язык
--    приложения выбирается на устройстве (может отличаться у одного
--    человека на телефоне и планшете) — поэтому храним его рядом с
--    токеном устройства. null — сервер возьмёт чешский.
alter table public.device_tokens
  add column if not exists locale text;

-- 2. Кто последним поменял статус заявки. Клиент может сам отменить
--    свою заявку — присылать ему же push "заявка отменена" незачем.
--    Вебхук не знает, кто сделал UPDATE, а триггер знает (auth.uid()),
--    поэтому записываем это в саму строку — Edge Function увидит поле
--    в payload вебхука.
alter table public.service_requests
  add column if not exists status_changed_by uuid
    references public.profiles (id) on delete set null;

create or replace function public.set_status_changed_by()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status
     or new.scheduled_at is distinct from old.scheduled_at then
    new.status_changed_by := auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_status_changed_by on public.service_requests;
create trigger trg_set_status_changed_by
  before update on public.service_requests
  for each row execute function public.set_status_changed_by();
