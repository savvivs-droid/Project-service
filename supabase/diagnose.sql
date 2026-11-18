-- Политики и права на request_read_state + сколько сообщений вообще есть.
select 'policy' as kind, policyname as name, cmd as info, coalesce(qual, '') || ' | ' || coalesce(with_check, '') as extra
from pg_policies where tablename = 'request_read_state'
union all
select 'grant', grantee, string_agg(privilege_type, ','), ''
from information_schema.role_table_grants
where table_name = 'request_read_state' and grantee in ('authenticated','anon')
group by grantee
union all
select 'rls', relname, relrowsecurity::text, ''
from pg_class where relname = 'request_read_state'
union all
select 'messages', count(*)::text, '', '' from public.request_messages
union all
select 'constraint', conname, pg_get_constraintdef(oid), '' from pg_constraint where conrelid = 'public.request_read_state'::regclass;
