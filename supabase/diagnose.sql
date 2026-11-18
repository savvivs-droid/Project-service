-- Отметки прочтения против последних сообщений другой стороны
-- (только время и роли, без текста сообщений).
select
  left(rrs.request_id::text, 8) as req,
  p.role::text as reader,
  rrs.last_read_at,
  (select max(rm.created_at) from public.request_messages rm
     where rm.request_id = rrs.request_id and rm.sender_id <> rrs.profile_id) as last_other_msg,
  now() as db_now
from public.request_read_state rrs
join public.profiles p on p.id = rrs.profile_id
order by rrs.last_read_at desc
limit 15;
