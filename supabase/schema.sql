-- =============================================================================
-- Схема базы данных для сервиса ремонта гастрооборудования.
--
-- Как применить:
-- Supabase Dashboard -> SQL Editor -> New query -> вставить весь файл -> Run.
-- Файл идемпотентен настолько, насколько это возможно для первого запуска
-- (use "if not exists" где это поддерживается), но рассчитан на запуск
-- один раз на чистой базе.
--
-- Роли в системе: 'client' (ответственный в заведении) и 'admin'
-- (сотрудник сервисной компании — сейчас админов заводят вручную, см.
-- раздел 6). Отдельной роли диспетчера нет: все заявки обрабатывают
-- администраторы.
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
create type public.user_role as enum ('client', 'admin');

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
  -- IČO — идентификационный номер организации в чешском реестре ARES.
  -- Не у всех заведений (добавленных вручную сотрудником) он обязателен,
  -- поэтому колонка nullable, но если указан — должен быть уникальным:
  -- это не даёт одному и тому же бизнесу завестись дважды через
  -- самостоятельную регистрацию клиента (см. handle_new_user ниже).
  ico text,
  -- Фото входной группы (фасад/вход заведения) — для узнаваемости
  -- заведения мастером на месте. Загружается администратором, см.
  -- lib/features/home/establishment_detail_screen.dart.
  entrance_photo_url text,
  connected_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create unique index establishments_ico_key
  on public.establishments (ico)
  where ico is not null;

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

-- Связь клиентов с заведениями — многие ко многим: один клиент может
-- состоять в нескольких заведениях (например, управляет сетью из
-- нескольких точек), в одном заведении может быть больше одного клиента.
-- profiles.establishment_id при этом остаётся — как заведение "по
-- умолчанию", выбранное при регистрации, но доступ (RLS) определяется
-- только через эту таблицу, см. is_establishment_member() ниже.
create table public.establishment_members (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  establishment_id uuid not null references public.establishments (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, establishment_id)
);

-- Оборудование, установленное в заведении
create table public.equipment (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments (id) on delete cascade,
  type text not null,
  model text,
  -- sticker_code (текстовый код с бирки) больше не используется в
  -- приложении — вместо ручного ввода кода фотографируют саму бирку,
  -- см. sticker_photo_url. Колонку оставили, вдруг пригодится позже
  -- (например, для распознавания кода с фото).
  sticker_code text unique,
  sticker_photo_url text,
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
  -- Заполняются администратором при закрытии заявки (см.
  -- lib/features/home/admin_request_detail_screen.dart) — стоимость
  -- ремонта (доход) и стоимость запчастей (расход), используются для
  -- вкладки "Статистика" у администратора.
  repair_cost numeric(10, 2),
  parts_cost numeric(10, 2),
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

-- Переписка по конкретной заявке — здесь клиент и администратор
-- согласовывают детали ремонта и стоимость. Сообщения не редактируются
-- и не удаляются (простая история чата), только читаются и добавляются.
create table public.request_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.service_requests (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

-- Отметка "прочитано до какого момента" по заявке — своя у каждого
-- участника переписки (клиент и админ читают чат независимо друг от
-- друга). Используется, чтобы посчитать непрочитанные сообщения (см.
-- unread_message_request_ids() ниже) и показать индикатор на вкладках
-- и карточках заявок, см. lib/services/request_message_repository.dart.
create table public.request_read_state (
  request_id uuid not null references public.service_requests (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (request_id, profile_id)
);

-- Токены устройств для push-уведомлений (Firebase Cloud Messaging) — один
-- пользователь может быть залогинен на нескольких устройствах, у каждого
-- свой токен, поэтому это отдельная таблица, а не колонка в profiles.
-- Заполняется приложением при входе (см.
-- lib/services/device_token_repository.dart), читается только серверной
-- частью (Edge Function send-push-notification, service role — в обход
-- RLS) при отправке пуша на новое сообщение чата.
create table public.device_tokens (
  token text primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null,
  updated_at timestamptz not null default now()
);

-- Индексы для внешних ключей, по которым мы часто фильтруем
create index idx_profiles_establishment on public.profiles (establishment_id);
create index idx_establishment_members_establishment on public.establishment_members (establishment_id);
create index idx_equipment_establishment on public.equipment (establishment_id);
create index idx_service_requests_establishment on public.service_requests (establishment_id);
create index idx_service_requests_client on public.service_requests (client_id);
create index idx_device_tokens_profile on public.device_tokens (profile_id);
create index idx_repair_history_equipment on public.repair_history (equipment_id);
create index idx_request_messages_request on public.request_messages (request_id, created_at);
create index idx_request_read_state_profile on public.request_read_state (profile_id);


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

-- Заведение "по умолчанию" (то, что указано в профиле — обычно первое,
-- заведённое при регистрации). Доступ (RLS) через эту функцию больше не
-- проверяется — только is_establishment_member() ниже; здесь она осталась
-- как значение для интерфейса (какое заведение выбрать при входе).
create or replace function public.current_user_establishment()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select establishment_id from public.profiles where id = auth.uid();
$$;

-- Состоит ли текущий пользователь в заведении p_establishment_id — на
-- этом строится доступ клиента к заведению, его оборудованию, заявкам и
-- истории ремонта (клиент может состоять в нескольких заведениях сразу).
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

create or replace function public.is_staff()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;


-- -----------------------------------------------------------------------------
-- 5. Row Level Security
-- -----------------------------------------------------------------------------
-- Общий принцип:
--   - Администратор (is_staff()) видит и может менять всё.
--   - Клиент видит заведения, где он состоит (может быть несколько), их
--     оборудование, заявки и историю ремонта — определяется через
--     is_establishment_member().

alter table public.establishments enable row level security;
alter table public.establishment_members enable row level security;
alter table public.profiles enable row level security;
alter table public.equipment enable row level security;
alter table public.service_requests enable row level security;
alter table public.service_request_equipment enable row level security;
alter table public.repair_history enable row level security;
alter table public.request_messages enable row level security;

-- === establishments ===
create policy "Админ видит все заведения, клиент — только свои"
  on public.establishments for select
  using (public.is_staff() or public.is_establishment_member(id));

create policy "Только админ меняет заведения вручную"
  on public.establishments for insert
  with check (public.is_staff());

create policy "Только админ обновляет заведения"
  on public.establishments for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только админ удаляет заведения"
  on public.establishments for delete
  using (public.is_staff());

-- === profiles ===
create policy "Свой профиль виден себе, админу — все профили"
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
-- через UPDATE можно поменять только админу — это дополнительно
-- защищено триггером trg_protect_profile_privileges ниже, потому что
-- Row Level Security не умеет ограничивать доступ к отдельным колонкам.

-- === establishment_members ===
create policy "Клиент видит свои связки с заведениями, админ — все"
  on public.establishment_members for select
  using (profile_id = auth.uid() or public.is_staff());

-- Прямая вставка/удаление из приложения не предусмотрены для клиента —
-- первая связка создаётся триггером handle_new_user при регистрации,
-- последующие — функцией add_client_establishment (раздел 6), обе
-- security definer и не подчиняются этим политикам. Явных insert/delete
-- политик для клиента нет, поэтому обычным пользователям через
-- обычный insert/delete это недоступно; администратору оставляем эту
-- возможность на будущее.
create policy "Только админ добавляет связки вручную"
  on public.establishment_members for insert
  with check (public.is_staff());

create policy "Только админ удаляет связки"
  on public.establishment_members for delete
  using (public.is_staff());

-- === equipment ===
create policy "Админ видит всё оборудование, клиент — своих заведений"
  on public.equipment for select
  using (public.is_staff() or public.is_establishment_member(establishment_id));

create policy "Только админ добавляет оборудование"
  on public.equipment for insert
  with check (public.is_staff());

create policy "Только админ редактирует оборудование"
  on public.equipment for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только админ удаляет оборудование"
  on public.equipment for delete
  using (public.is_staff());

-- === service_requests ===
create policy "Админ видит все заявки, клиент — заявки своих заведений"
  on public.service_requests for select
  using (public.is_staff() or public.is_establishment_member(establishment_id));

create policy "Клиент создаёт заявку от своего имени и заведения"
  on public.service_requests for insert
  with check (
    public.is_staff()
    or (client_id = auth.uid() and public.is_establishment_member(establishment_id))
  );

create policy "Админ меняет любые заявки, клиент — только новую свою"
  on public.service_requests for update
  using (
    public.is_staff()
    or (client_id = auth.uid() and status = 'new')
  )
  with check (
    public.is_staff()
    or (client_id = auth.uid() and status in ('new', 'cancelled'))
  );

create policy "Только админ удаляет заявки"
  on public.service_requests for delete
  using (public.is_staff());

-- === service_request_equipment (связующая таблица) ===
create policy "Видимость связки как у самой заявки"
  on public.service_request_equipment for select
  using (
    exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and (public.is_staff() or public.is_establishment_member(sr.establishment_id))
    )
  );

create policy "Добавлять оборудование в заявку может её автор или админ"
  on public.service_request_equipment for insert
  with check (
    exists (
      select 1 from public.service_requests sr
      where sr.id = request_id
        and (public.is_staff() or sr.client_id = auth.uid())
    )
  );

create policy "Только админ убирает оборудование из заявки"
  on public.service_request_equipment for delete
  using (public.is_staff());

-- === repair_history ===
create policy "Админ видит всю историю, клиент — историю своего оборудования"
  on public.repair_history for select
  using (
    public.is_staff()
    or exists (
      select 1 from public.equipment e
      where e.id = equipment_id and public.is_establishment_member(e.establishment_id)
    )
  );

create policy "Только админ ведёт историю ремонта"
  on public.repair_history for insert
  with check (public.is_staff());

create policy "Только админ редактирует историю ремонта"
  on public.repair_history for update
  using (public.is_staff())
  with check (public.is_staff());

create policy "Только админ удаляет историю ремонта"
  on public.repair_history for delete
  using (public.is_staff());

-- === request_messages (чат по заявке) ===
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

-- Сообщения не редактируются и не удаляются — политик update/delete
-- нет намеренно, RLS по умолчанию запрещает всё, что не разрешено явно.

-- === request_read_state (отметки прочтения чата) ===
alter table public.request_read_state enable row level security;

create policy "Каждый видит свою отметку прочтения, админ — все"
  on public.request_read_state for select
  using (profile_id = auth.uid() or public.is_staff());

create policy "Отмечает прочтение только от своего имени"
  on public.request_read_state for insert
  with check (profile_id = auth.uid());

create policy "Обновляет только свою отметку прочтения"
  on public.request_read_state for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- === device_tokens (push-уведомления) ===
alter table public.device_tokens enable row level security;

-- Читать чужие токены изнутри приложения не нужно никому, даже
-- администратору — их читает только Edge Function по service role
-- (в обход RLS), поэтому select-политика разрешает видеть только свои.
create policy "Каждый видит только свои токены устройств"
  on public.device_tokens for select
  using (profile_id = auth.uid());

create policy "Заводит токен только от своего имени"
  on public.device_tokens for insert
  with check (profile_id = auth.uid());

create policy "Обновляет только свой токен"
  on public.device_tokens for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy "Удаляет только свой токен"
  on public.device_tokens for delete
  using (profile_id = auth.uid());

-- Включаем Realtime для чата — без этого supabase_flutter .stream(...)
-- не будет получать новые сообщения без ручного обновления экрана.
-- request_read_state — для живого обновления индикатора непрочитанного
-- на всех вкладках (см. RequestMessageRepository.watchUnreadRequestIds).
alter publication supabase_realtime add table public.request_messages;
alter publication supabase_realtime add table public.request_read_state;

-- Заявки (их id), где есть хоть одно сообщение от другой стороны,
-- написанное позже последней отметки прочтения текущего пользователя
-- (или вообще без отметки — тогда читаем "непрочитано с самого начала").
-- Используется для индикатора непрочитанного в интерфейсе.
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


-- -----------------------------------------------------------------------------
-- 6. Автоматическое создание профиля при регистрации клиента
-- -----------------------------------------------------------------------------
-- Регистрация в приложении — только для клиентов, и только самостоятельная:
-- клиент вводит email/пароль, свои данные и данные своего заведения (в том
-- числе IČO — см. lib/services/ares_service.dart), приложение вызывает
-- supabase.auth.signUp(...), передавая всё это как метаданные пользователя
-- (raw_user_meta_data). Триггер ниже срабатывает сразу при создании строки
-- в auth.users — даже если ещё требуется подтверждение email — и создаёт
-- заведение и профиль клиента одним махом.
--
-- Администраторов эта регистрация не касается: их заводят вручную (раздел 7).

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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Клиент добавляет себе ещё одно заведение (после регистрации, когда у
-- него уже есть аккаунт) — тот же принцип, что и в handle_new_user выше:
-- создаёт заведение и сразу привязывает текущего пользователя к нему
-- через establishment_members. security definer нужен, потому что
-- обычная insert-политика на establishments разрешена только админу
-- (раздел 5) — это единственная контролируемая лазейка для клиента.
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

-- Запрещаем пользователю (кроме админа) менять себе роль или заведение
-- через обычный UPDATE — RLS выше это не может ограничить на уровне
-- колонок, поэтому здесь дополнительная защита триггером.
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
-- 7. Администраторы (заводятся вручную)
-- -----------------------------------------------------------------------------
-- Регистрация через приложение доступна только клиентам, поэтому
-- администраторов заводят вручную через Dashboard.
--
-- Важно: триггер on_auth_user_created (раздел 6) срабатывает на любую
-- вставку в auth.users — в том числе на создание пользователя вручную
-- через Dashboard, где данных заведения нет. Без обхода этого триггера
-- Dashboard откажет с ошибкой "failed to create user".
--
-- "alter table auth.users disable trigger ..." тут не сработает: таблицей
-- auth.users в Supabase владеет системная роль, а не ваш аккаунт. Зато вы
-- владеете функцией handle_new_user(), которую вызывает триггер, — значит,
-- можно временно превратить её в пустышку, не трогая сам триггер. Порядок
-- (повторить для каждого нового администратора):
--
--   1. Временно заменить тело функции на "begin return new; end;"
--      (create or replace function ... as $$ begin return new; end; $$;).
--   2. Authentication -> Users -> Add user — создать пользователя с email/паролем.
--   3. Скопировать его id (uuid).
--   4. Выполнить в SQL Editor одним запросом (обязательно вместе с полным
--      восстановлением тела функции — см. раздел 6 выше, — иначе обычная
--      регистрация клиентов в приложении останется сломанной для всех):
--
--      insert into public.profiles (id, full_name, phone, role)
--      values ('<uuid пользователя>', 'Имя Фамилия', '+70000000000', 'admin');
--
-- После этого администратор сможет входить в приложение, видеть все
-- заведения, оборудование и заявки, и обрабатывать их.


-- -----------------------------------------------------------------------------
-- 8. Хранилище фото оборудования (Supabase Storage)
-- -----------------------------------------------------------------------------
-- Бакет "equipment-photos" — сюда попадают фото бирки (стикера) и самого
-- оборудования, которые снимает администратор при добавлении/редактировании
-- оборудования (см. lib/services/equipment_photo_service.dart).
--
-- Бакет публичный на чтение (public = true): это упрощает отображение фото
-- в приложении — не нужно генерировать подписанные ссылки — и приемлемо,
-- так как в нём нет ничего чувствительнее фото кухонной техники. Если
-- позже это станет важно, можно сделать бакет приватным и переключиться
-- на createSignedUrl(). Загрузка/изменение/удаление — только администратору.

insert into storage.buckets (id, name, public)
values ('equipment-photos', 'equipment-photos', true)
on conflict (id) do nothing;

create policy "Фото оборудования доступны на чтение всем"
  on storage.objects for select
  using (bucket_id = 'equipment-photos');

create policy "Только админ загружает фото оборудования"
  on storage.objects for insert
  with check (bucket_id = 'equipment-photos' and public.is_staff());

create policy "Только админ изменяет фото оборудования"
  on storage.objects for update
  using (bucket_id = 'equipment-photos' and public.is_staff())
  with check (bucket_id = 'equipment-photos' and public.is_staff());

create policy "Только админ удаляет фото оборудования"
  on storage.objects for delete
  using (bucket_id = 'equipment-photos' and public.is_staff());
