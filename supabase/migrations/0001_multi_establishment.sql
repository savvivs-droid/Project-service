-- =============================================================================
-- Миграция: несколько заведений на одного клиента.
--
-- Это НЕ повторный прогон supabase/schema.sql целиком (тот рассчитан на
-- чистую базу и упадёт на "create table" для уже существующих таблиц) —
-- это точечный патч поверх уже работающей базы с реальными данными.
--
-- Как применить: Supabase Dashboard -> SQL Editor -> New query -> вставить
-- весь файл -> Run. Один раз.
--
-- После применения schema.sql в репозитории снова описывает актуальную
-- схему целиком (для будущих чистых установок) — эта миграция и
-- schema.sql теперь согласованы между собой.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Новая таблица связи клиент<->заведение (многие ко многим)
-- -----------------------------------------------------------------------------
create table if not exists public.establishment_members (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  establishment_id uuid not null references public.establishments (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, establishment_id)
);

create index if not exists idx_establishment_members_establishment
  on public.establishment_members (establishment_id);

alter table public.establishment_members enable row level security;

-- -----------------------------------------------------------------------------
-- 2. Бэкфилл — у существующих клиентов уже есть establishment_id в профиле,
-- превращаем это в первую запись членства, иначе после переключения RLS
-- на establishment_members все действующие клиенты потеряют доступ к
-- своему заведению.
-- -----------------------------------------------------------------------------
insert into public.establishment_members (profile_id, establishment_id)
select id, establishment_id
from public.profiles
where establishment_id is not null
on conflict do nothing;

-- -----------------------------------------------------------------------------
-- 3. Функция-помощник для RLS
-- -----------------------------------------------------------------------------
create or replace function public.is_establishment_member(p_establishment_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.establishment_members
    where establishment_id = p_establishment_id and profile_id = auth.uid()
  );
$$;

-- current_user_establishment() больше не используется в RLS — оставлена
-- как значение "заведение по умолчанию" для интерфейса, тело не меняется.

-- -----------------------------------------------------------------------------
-- 4. Политики RLS для establishment_members
-- -----------------------------------------------------------------------------
drop policy if exists "Клиент видит свои связки с заведениями, админ — все" on public.establishment_members;
create policy "Клиент видит свои связки с заведениями, админ — все"
  on public.establishment_members for select
  using (profile_id = auth.uid() or public.is_staff());

drop policy if exists "Только админ добавляет связки вручную" on public.establishment_members;
create policy "Только админ добавляет связки вручную"
  on public.establishment_members for insert
  with check (public.is_staff());

drop policy if exists "Только админ удаляет связки" on public.establishment_members;
create policy "Только админ удаляет связки"
  on public.establishment_members for delete
  using (public.is_staff());

-- -----------------------------------------------------------------------------
-- 5. Перевод существующих политик с current_user_establishment() на
-- is_establishment_member() — drop + create, т.к. у policy нет "or replace".
-- -----------------------------------------------------------------------------

-- establishments
drop policy if exists "Админ видит все заведения, клиент — только своё" on public.establishments;
drop policy if exists "Админ видит все заведения, клиент — только свои" on public.establishments;
create policy "Админ видит все заведения, клиент — только свои"
  on public.establishments for select
  using (public.is_staff() or public.is_establishment_member(id));

-- equipment
drop policy if exists "Админ видит всё оборудование, клиент — своего заведения" on public.equipment;
drop policy if exists "Админ видит всё оборудование, клиент — своих заведений" on public.equipment;
create policy "Админ видит всё оборудование, клиент — своих заведений"
  on public.equipment for select
  using (public.is_staff() or public.is_establishment_member(establishment_id));

-- service_requests
drop policy if exists "Админ видит все заявки, клиент — заявки своего заведения" on public.service_requests;
drop policy if exists "Админ видит все заявки, клиент — заявки своих заведений" on public.service_requests;
create policy "Админ видит все заявки, клиент — заявки своих заведений"
  on public.service_requests for select
  using (public.is_staff() or public.is_establishment_member(establishment_id));

drop policy if exists "Клиент создаёт заявку от своего имени и заведения" on public.service_requests;
create policy "Клиент создаёт заявку от своего имени и заведения"
  on public.service_requests for insert
  with check (
    public.is_staff()
    or (client_id = auth.uid() and public.is_establishment_member(establishment_id))
  );

-- service_request_equipment
drop policy if exists "Видимость связки как у самой заявки" on public.service_request_equipment;
create policy "Видимость связки как у самой заявки"
  on public.service_request_equipment for select
  using (
    exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and (public.is_staff() or public.is_establishment_member(sr.establishment_id))
    )
  );

-- repair_history
drop policy if exists "Админ видит всю историю, клиент — историю своего оборудования" on public.repair_history;
create policy "Админ видит всю историю, клиент — историю своего оборудования"
  on public.repair_history for select
  using (
    public.is_staff()
    or exists (
      select 1 from public.equipment e
      where e.id = equipment_id and public.is_establishment_member(e.establishment_id)
    )
  );

-- request_messages
drop policy if exists "Сообщения видит админ и клиент своего заведения" on public.request_messages;
drop policy if exists "Сообщения видит админ и клиент своих заведений" on public.request_messages;
create policy "Сообщения видит админ и клиент своих заведений"
  on public.request_messages for select
  using (
    public.is_staff()
    or exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and public.is_establishment_member(sr.establishment_id)
    )
  );

drop policy if exists "Писать может админ или клиент своего заведения, только от своего имени" on public.request_messages;
drop policy if exists "Писать может админ или клиент своих заведений, только от своего имени" on public.request_messages;
create policy "Писать может админ или клиент своих заведений, только от своего имени"
  on public.request_messages for insert
  with check (
    sender_id = auth.uid()
    and (
      public.is_staff()
      or exists (
        select 1 from public.service_requests sr
        where sr.id = request_id
          and public.is_establishment_member(sr.establishment_id)
      )
    )
  );

-- -----------------------------------------------------------------------------
-- 6. handle_new_user — регистрация теперь дополнительно заводит запись
-- членства для только что созданного заведения.
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_establishment_id uuid;
  v_establishment_name text;
  v_ico text;
begin
  v_establishment_name := new.raw_user_meta_data ->> 'new_establishment_name';

  if v_establishment_name is null then
    raise exception 'Отсутствуют данные заведения для регистрации клиента';
  end if;

  v_ico := nullif(new.raw_user_meta_data ->> 'new_establishment_ico', '');

  if v_ico is not null
     and exists (select 1 from public.establishments where ico = v_ico)
  then
    raise exception 'Заведение с таким IČO уже зарегистрировано в системе';
  end if;

  insert into public.establishments (name, address, contact_phone, ico)
  values (
    v_establishment_name,
    new.raw_user_meta_data ->> 'new_establishment_address',
    new.raw_user_meta_data ->> 'new_establishment_contact_phone',
    v_ico
  )
  returning id into v_establishment_id;

  insert into public.profiles (id, full_name, phone, role, establishment_id)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone',
    'client',
    v_establishment_id
  );

  insert into public.establishment_members (profile_id, establishment_id)
  values (new.id, v_establishment_id);

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 7. Новая функция — клиент сам добавляет себе ещё одно заведение
-- -----------------------------------------------------------------------------
create or replace function public.add_client_establishment(
  p_ico text,
  p_name text,
  p_address text,
  p_contact_phone text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_establishment_id uuid;
  v_ico text;
begin
  if public.current_user_role() is distinct from 'client' then
    raise exception 'Добавлять заведение может только клиент';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'Не указано название заведения';
  end if;

  v_ico := nullif(p_ico, '');

  if v_ico is not null
     and exists (select 1 from public.establishments where ico = v_ico)
  then
    raise exception 'Заведение с таким IČO уже зарегистрировано в системе';
  end if;

  insert into public.establishments (name, address, contact_phone, ico)
  values (p_name, p_address, p_contact_phone, v_ico)
  returning id into v_establishment_id;

  insert into public.establishment_members (profile_id, establishment_id)
  values (auth.uid(), v_establishment_id);

  return v_establishment_id;
end;
$$;
