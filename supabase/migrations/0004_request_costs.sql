-- =============================================================================
-- Миграция: стоимость ремонта и запчастей на заявке (для статистики
-- администратора — доход/расход).
--
-- Точечный патч поверх уже работающей базы. Как применить: Supabase
-- Dashboard -> SQL Editor -> New query -> вставить весь файл -> Run.
-- Один раз.
-- =============================================================================

alter table public.service_requests
  add column if not exists repair_cost numeric(10, 2);

alter table public.service_requests
  add column if not exists parts_cost numeric(10, 2);
