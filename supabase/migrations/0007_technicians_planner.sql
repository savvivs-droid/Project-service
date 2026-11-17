-- =============================================================================
-- Миграция: техники и планировщик визитов у администратора.
--
-- Точечный патч поверх уже работающей базы (не повторный прогон
-- schema.sql). Как применить: Supabase Dashboard -> SQL Editor ->
-- New query -> вставить весь файл -> Run. Один раз.
-- =============================================================================

-- Техники сервиса. Своего входа в приложение у них пока нет — это просто
-- список, который ведёт администратор (вкладка "Планировщик" -> "Техники").
-- Техника не удаляют, а скрывают (is_active = false), чтобы старые
-- визиты в планировщике не потеряли исполнителя.
create table if not exists public.technicians (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  -- Цвет блоков визитов в планировщике, '#RRGGBB'.
  color text not null default '#2F9E63',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.technicians enable row level security;

-- Клиенты техников не видят вообще (имя техника клиенту не показываем).
drop policy if exists "Только админ видит техников" on public.technicians;
create policy "Только админ видит техников"
  on public.technicians for select
  using (public.is_staff());

drop policy if exists "Только админ добавляет техников" on public.technicians;
create policy "Только админ добавляет техников"
  on public.technicians for insert
  with check (public.is_staff());

drop policy if exists "Только админ редактирует техников" on public.technicians;
create policy "Только админ редактирует техников"
  on public.technicians for update
  using (public.is_staff())
  with check (public.is_staff());

-- Кто едет на заявку и сколько часов займёт визит (начало — уже
-- существующий scheduled_at, всегда ровный час с 8:00 до 21:00).
alter table public.service_requests
  add column if not exists technician_id uuid
    references public.technicians (id) on delete set null;

alter table public.service_requests
  add column if not exists duration_hours smallint
    check (duration_hours between 1 and 14);

create index if not exists idx_service_requests_technician_schedule
  on public.service_requests (technician_id, scheduled_at);
