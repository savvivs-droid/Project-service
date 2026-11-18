-- Права роли authenticated на таблицы public (has_table_privilege).
select c.relname as t,
  has_table_privilege('authenticated', c.oid, 'SELECT') as sel,
  has_table_privilege('authenticated', c.oid, 'INSERT') as ins,
  has_table_privilege('authenticated', c.oid, 'UPDATE') as upd
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by 1;
