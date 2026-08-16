-- =============================================================================
-- Миграция: индикатор непрочитанных сообщений чата.
--
-- Точечный патч поверх уже работающей базы (не повторный прогон
-- schema.sql). Как применить: Supabase Dashboard -> SQL Editor ->
-- New query -> вставить весь файл -> Run. Один раз.
-- =============================================================================

create table if not exists public.request_read_state (
  request_id uuid not null references public.service_requests (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (request_id, profile_id)
);

create index if not exists idx_request_read_state_profile
  on public.request_read_state (profile_id);

alter table public.request_read_state enable row level security;

drop policy if exists "Каждый видит свою отметку прочтения, админ — все" on public.request_read_state;
create policy "Каждый видит свою отметку прочтения, админ — все"
  on public.request_read_state for select
  using (profile_id = auth.uid() or public.is_staff());

drop policy if exists "Отмечает прочтение только от своего имени" on public.request_read_state;
create policy "Отмечает прочтение только от своего имени"
  on public.request_read_state for insert
  with check (profile_id = auth.uid());

drop policy if exists "Обновляет только свою отметку прочтения" on public.request_read_state;
create policy "Обновляет только свою отметку прочтения"
  on public.request_read_state for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- Идемпотентно: добавление таблицы, которая уже есть в публикации,
-- вызывает ошибку, поэтому проверяем перед добавлением.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'request_read_state'
  ) then
    alter publication supabase_realtime add table public.request_read_state;
  end if;
end $$;

create or replace function public.unread_message_request_ids()
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select distinct rm.request_id
  from public.request_messages rm
  join public.service_requests sr on sr.id = rm.request_id
  left join public.request_read_state rrs
    on rrs.request_id = rm.request_id and rrs.profile_id = auth.uid()
  where rm.sender_id <> auth.uid()
    and rm.created_at > coalesce(rrs.last_read_at, '-infinity'::timestamptz)
    and (public.is_staff() or public.is_establishment_member(sr.establishment_id));
$$;
