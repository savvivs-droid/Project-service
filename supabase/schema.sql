-- =============================================================================
-- Схема базы данных для сервиса ремонта гастрооборудования.
--
-- Как применить:
-- Supabase Dashboard -> SQL Editor -> New query -> вставить весь файл -> Run.
-- Файл идемпотентен настолько, насколько это возможно для первого запуска
-- (use "if not exists" где это поддерживается), но рассчитан на запуск
-- один раз на чистой базе.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Расширения
-- -----------------------------------------------------------------------------
-- gen_random_uuid() для генерации первичных ключей.
create extension if not exists pgcrypto;


-- -----------------------------------------------------------------------------
-- 2. Типы-перечисления (enum)
-- -----------------------------------------------------------------------------
-- Роль пользователя. Значения должны совпадать с lib/core/constants/user_role.dart
create type public.user_role as enum ('client', 'dispatcher', 'admin');

-- Статус единицы оборудования.
create type public.equipment_status as enum ('active', 'in_repair', 'decommissioned');

-- Статус заявки на ремонт: Новая -> Согласовано время -> Выполнено (либо -> Отменено)
create type public.request_status as enum ('new', 'scheduled', 'done', 'cancelled');


-- -----------------------------------------------------------------------------
-- 3. Таблицы
-- -----------------------------------------------------------------------------

-- Заведения-клиенты (кафе, рестораны, фастфуды)
create table public.establishments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  contact_phone text,
  connected_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Профили пользователей. id ссылается на auth.users — таблицу, которую
-- уже создал и обслуживает сам Supabase Auth. Мы не храним email/пароль
-- здесь — только то, что нужно для нашей бизнес-логики.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text,
  role public.user_role not null default 'client',
  establishment_id uuid references public.establishments (id) on delete set null,
  created_at timestamptz not null default now()
);

-- Коды приглашений. Администратор/диспетчер создаёт код для конкретного
-- заведения (роль 'client') или для нового сотрудника (роль 'dispatcher'
-- или 'admin', establishment_id = null). Пользователь вводит код при
-- регистрации — это единственный способ получить роль и заведение
-- (пользователь не может выбрать их сам, см. handle_new_user ниже).
create table public.invite_codes (
  code text primary key,
  role public.user_role not null,
  establishment_id uuid references public.establishments (id) on delete cascade,
  created_by uuid references public.profiles (id) on delete set null,
  used_by uuid references public.profiles (id) on delete set null,
  used_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint invite_client_requires_establishment
    check (role <> 'client' or establishment_id is not null)
);

-- Оборудование, установленное в заведении
create table public.equipment (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments (id) on delete cascade,
  type text not null,
  model text,
  sticker_code text unique,
  photos text[] not null default '{}',
  installed_at date,
  status public.equipment_status not null default 'active',
  created_at timestamptz not null default now()
);

-- Заявки на ремонт
create table public.service_requests (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments (id) on delete cascade,
  client_id uuid not null references public.profiles (id) on delete restrict,
  description text not null,
  photos text[] not null default '{}',
  status public.request_status not null default 'new',
  scheduled_at timestamptz,
  completed_at timestamptz,
  technician_comment text,
  created_at timestamptz not null default now()
);

-- Заявка может относиться к нескольким единицам оборудования —
-- связующая таблица многие-ко-многим.
create table public.service_request_equipment (
  request_id uuid not null references public.service_requests (id) on delete cascade,
  equipment_id uuid not null references public.equipment (id) on delete cascade,
  primary key (request_id, equipment_id)
);

-- История ремонта конкретной единицы оборудования
create table public.repair_history (
  id uuid primary key default gen_random_uuid(),
  equipment_id uuid not null references public.equipment (id) on delete cascade,
  request_id uuid references public.service_requests (id) on delete set null,
  performed_at timestamptz not null default now(),
  work_description text not null,
  result text,
  created_at timestamptz not null default now()
);

-- Индексы для внешних ключей, по которым мы часто фильтруем
create index idx_profiles_establishment on public.profiles (establishment_id);
create index idx_equipment_establishment on public.equipment (establishment_id);
create index idx_service_requests_establishment on public.service_requests (establishment_id);
create index idx_service_requests_client on public.service_requests (client_id);
create index idx_repair_history_equipment on public.repair_history (equipment_id);
create index idx_invite_codes_establishment on public.invite_codes (establishment_id);


-- -----------------------------------------------------------------------------
-- 4. Вспомогательные функции для RLS
-- -----------------------------------------------------------------------------
-- SECURITY DEFINER означает, что функция выполняется с правами того, кто
-- её создал (владельца), а не вызывающего пользователя — это позволяет ей
-- прочитать таблицу profiles в обход RLS-политик, которые сами эту
-- функцию используют. Без этого получилась бы бесконечная рекурсия:
-- политика на profiles вызывает функцию, которая читает profiles,
-- что снова требует проверки политики...

create or replace function public.current_user_role()
returns public.user_role
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_user_establishment()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select establishment_id from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('dispatcher', 'admin')
  );
$$;


-- -----------------------------------------------------------------------------
-- 5. Row Level Security
-- -----------------------------------------------------------------------------
-- Общий принцип:
--   - Диспетчер и администратор (is_staff()) видят и могут менять всё.
--   - Клиент видит только своё заведение, его оборудование, заявки и
--     историю ремонта — определяется через current_user_establishment().

alter table public.establishments enable row level security;
alter table public.profiles enable row level security;
alter table public.invite_codes enable row level security;
alter table public.equipment enable row level security;
alter table public.service_requests enable row level security;
alter table public.service_request_equipment enable row level security;
alter table public.repair_history enable row level security;

-- === establishments ===
create policy "Сотрудники видят все заведения, клиент — только своё"
  on public.establishments for select
  using (public.is_staff() or id = public.current_user_establishment());

create policy "Только сотрудники создают/меняют заведения"
  on public.establishments for insert
  with check (public.is_staff());

create policy "Только сотрудники обновляют заведения"
  on public.establishments for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только сотрудники удаляют заведения"
  on public.establishments for delete
  using (public.is_staff());

-- === profiles ===
create policy "Свой профиль виден себе, сотрудникам — все профили"
  on public.profiles for select
  using (id = auth.uid() or public.is_staff());

-- Прямая вставка профиля из приложения не предусмотрена — профиль
-- создаётся автоматически триггером handle_new_user (раздел 6) при
-- регистрации. Явной insert-политики нет, поэтому обычным пользователям
-- вставка запрещена; триггер же выполняется с правами определившей его
-- функции и не подчиняется этому ограничению.

create policy "Пользователь может обновить свой профиль"
  on public.profiles for update
  using (id = auth.uid() or public.is_staff())
  with check (id = auth.uid() or public.is_staff());

-- update-политика выше разрешает менять свою строку, но роль и заведение
-- через UPDATE можно поменять только сотруднику — это дополнительно
-- защищено триггером trg_protect_profile_privileges ниже, потому что
-- Row Level Security не умеет ограничивать доступ к отдельным колонкам.

-- === invite_codes ===
create policy "Коды приглашений видят только сотрудники"
  on public.invite_codes for select
  using (public.is_staff());

create policy "Диспетчер создаёт коды для клиентов, админ — любые"
  on public.invite_codes for insert
  with check (
    public.current_user_role() = 'admin'
    or (public.current_user_role() = 'dispatcher' and role = 'client')
  );

create policy "Только админ меняет и удаляет коды приглашений"
  on public.invite_codes for update
  using (public.current_user_role() = 'admin')
  with check (public.current_user_role() = 'admin');

create policy "Только админ удаляет коды приглашений"
  on public.invite_codes for delete
  using (public.current_user_role() = 'admin');

-- === equipment ===
create policy "Сотрудники видят всё оборудование, клиент — своего заведения"
  on public.equipment for select
  using (public.is_staff() or establishment_id = public.current_user_establishment());

create policy "Только сотрудники добавляют оборудование"
  on public.equipment for insert
  with check (public.is_staff());

create policy "Только сотрудники редактируют оборудование"
  on public.equipment for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только сотрудники удаляют оборудование"
  on public.equipment for delete
  using (public.is_staff());

-- === service_requests ===
create policy "Сотрудники видят все заявки, клиент — заявки своего заведения"
  on public.service_requests for select
  using (public.is_staff() or establishment_id = public.current_user_establishment());

create policy "Клиент создаёт заявку от своего имени и заведения"
  on public.service_requests for insert
  with check (
    public.is_staff()
    or (client_id = auth.uid() and establishment_id = public.current_user_establishment())
  );

create policy "Сотрудники меняют любые заявки, клиент — только новую свою"
  on public.service_requests for update
  using (
    public.is_staff()
    or (client_id = auth.uid() and status = 'new')
  )
  with check (
    public.is_staff()
    or (client_id = auth.uid() and status in ('new', 'cancelled'))
  );

create policy "Только сотрудники удаляют заявки"
  on public.service_requests for delete
  using (public.is_staff());

-- === service_request_equipment (связующая таблица) ===
create policy "Видимость связки как у самой заявки"
  on public.service_request_equipment for select
  using (
    exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and (public.is_staff() or sr.establishment_id = public.current_user_establishment())
    )
  );

create policy "Добавлять оборудование в заявку может её автор или сотрудник"
  on public.service_request_equipment for insert
  with check (
    exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and (public.is_staff() or sr.client_id = auth.uid())
    )
  );

create policy "Только сотрудники убирают оборудование из заявки"
  on public.service_request_equipment for delete
  using (public.is_staff());

-- === repair_history ===
create policy "Сотрудники видят всю историю, клиент — историю своего оборудования"
  on public.repair_history for select
  using (
    public.is_staff()
    or exists (
      select 1 from public.equipment e
      where e.id = equipment_id and e.establishment_id = public.current_user_establishment()
    )
  );

create policy "Только сотрудники ведут историю ремонта"
  on public.repair_history for insert
  with check (public.is_staff());

create policy "Только сотрудники редактируют историю ремонта"
  on public.repair_history for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только сотрудники удаляют историю ремонта"
  on public.repair_history for delete
  using (public.is_staff());


-- -----------------------------------------------------------------------------
-- 6. Автоматическое создание профиля при регистрации по коду приглашения
-- -----------------------------------------------------------------------------
-- При вызове supabase.auth.signUp(...) на клиенте мы передаём invite_code,
-- full_name и phone в поле "data" (это попадает в auth.users.raw_user_meta_data).
-- Триггер ниже срабатывает сразу при создании строки в auth.users — даже
-- если ещё требуется подтверждение email — и:
--   1. находит неиспользованный, непросроченный код приглашения;
--   2. создаёт профиль с ролью и establishment_id ИЗ КОДА (не из данных,
--      присланных клиентом, — так пользователь не может "назначить себе"
--      роль администратора);
--   3. помечает код как использованный.
-- Если код неверный/использован/просрочен — исключение отменяет всю
-- операцию регистрации, и Supabase Auth вернёт ошибку в приложение.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invite_codes%rowtype;
  v_establishment_id uuid;
  v_new_establishment_name text;
begin
  -- Клиент может зарегистрироваться без кода приглашения, сразу заведя
  -- своё заведение (самостоятельный онбординг). Признак такой регистрации —
  -- метаданные new_establishment_name вместо invite_code. Роль в этом
  -- случае жёстко 'client' — самостоятельно завести себе роль сотрудника
  -- так нельзя, для этого по-прежнему нужен код приглашения (см. ниже).
  v_new_establishment_name := new.raw_user_meta_data ->> 'new_establishment_name';

  if v_new_establishment_name is not null then
    insert into public.establishments (name, address, contact_phone)
    values (
      v_new_establishment_name,
      new.raw_user_meta_data ->> 'new_establishment_address',
      new.raw_user_meta_data ->> 'new_establishment_contact_phone'
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

    return new;
  end if;

  -- Иначе — обычный путь по коду приглашения (клиент, привязанный к уже
  -- существующему заведению, либо сотрудник — диспетчер/админ).
  select * into v_invite
  from public.invite_codes
  where code = new.raw_user_meta_data ->> 'invite_code'
    and used_by is null
    and (expires_at is null or expires_at > now())
  for update;

  if v_invite is null then
    raise exception 'Код приглашения недействителен, уже использован или просрочен';
  end if;

  insert into public.profiles (id, full_name, phone, role, establishment_id)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone',
    v_invite.role,
    v_invite.establishment_id
  );

  update public.invite_codes
  set used_by = new.id, used_at = now()
  where code = v_invite.code;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Запрещаем пользователю (кроме сотрудников) менять себе роль или
-- заведение через обычный UPDATE — RLS выше это не может ограничить
-- на уровне колонок, поэтому здесь дополнительная защита триггером.
create or replace function public.protect_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (new.role is distinct from old.role
      or new.establishment_id is distinct from old.establishment_id)
     and not public.is_staff() then
    raise exception 'Изменение роли или заведения недоступно';
  end if;
  return new;
end;
$$;

create trigger trg_protect_profile_privileges
  before update on public.profiles
  for each row execute function public.protect_profile_privileges();


-- -----------------------------------------------------------------------------
-- 7. Первый администратор (сделать вручную один раз)
-- -----------------------------------------------------------------------------
-- Коды приглашений создают только сотрудники, а самый первый сотрудник
-- ещё не может иметь код (его некому было выдать). Поэтому первого
-- администратора нужно создать вручную.
--
-- Важно: триггер on_auth_user_created (раздел 6) срабатывает на любую
-- вставку в auth.users — в том числе на создание пользователя вручную
-- через Dashboard, где кода приглашения нет. Без обхода этого триггера
-- Dashboard откажет с ошибкой "failed to create user".
--
-- "alter table auth.users disable trigger ..." тут не сработает: таблицей
-- auth.users в Supabase владеет системная роль, а не ваш аккаунт. Зато вы
-- владеете функцией handle_new_user(), которую вызывает триггер, — значит,
-- можно временно превратить её в пустышку, не трогая сам триггер. Порядок:
--
--   1. Временно заменить тело функции на "begin return new; end;"
--      (create or replace function ... as $$ begin return new; end; $$;).
--   2. Authentication -> Users -> Add user — создать пользователя с email/паролем.
--   3. Скопировать его id (uuid).
--   4. Выполнить в SQL Editor одним запросом (обязательно вместе с полным
--      восстановлением тела функции — см. раздел 6 выше, — иначе обычная
--      регистрация по коду в приложении останется сломанной для всех):
--
--      insert into public.profiles (id, full_name, phone, role)
--      values ('<uuid пользователя>', 'Имя Фамилия', '+70000000000', 'admin');
--
-- После этого администратор сможет входить в приложение и создавать
-- коды приглашений для диспетчеров и клиентов через будущий экран
-- администрирования (следующие этапы).
