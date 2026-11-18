-- Отметки прочтения против последних сообщений другой стороны.
select 'read' as k, left(rrs.request_id::text, 8) as req, p.role::text as who,
  rrs.last_read_at::text as t1,
  (select max(rm.created_at) from public.request_messages rm
     where rm.request_id = rrs.request_id and rm.sender_id <> rrs.profile_id)::text as t2
from public.request_read_state rrs
join public.profiles p on p.id = rrs.profile_id
union all
select 'msg', left(rm.request_id::text, 8), p.role::text, rm.created_at::text, ''
from public.request_messages rm join public.profiles p on p.id = rm.sender_id
union all
select 'now', '', '', now()::text, '';
-- run 1795037837
