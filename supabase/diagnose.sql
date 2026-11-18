-- Права роли authenticated на таблицы public.
select c.relname as table_name,
  coalesce((select string_agg(privilege_type, ',' order by privilege_type)
   from information_schema.role_table_grants g
   where g.table_schema = 'public' and g.table_name = c.relname and g.grantee = 'authenticated'), '-') as authenticated
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by 1;
