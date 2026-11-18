-- Что unread_message_request_ids() возвращает администратору + её текущее определение.
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from public.profiles where role = 'admin' limit 1), 'role', 'authenticated')::text,
  true);
select 'unread' as k, u::text as v from public.unread_message_request_ids() u
union all
select 'def', pg_get_functiondef('public.unread_message_request_ids'::regproc);
