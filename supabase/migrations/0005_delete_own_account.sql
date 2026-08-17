-- =============================================================================
-- Миграция: RPC самостоятельного удаления аккаунта клиентом (см.
-- ClientProfileTab / AuthRepository.deleteOwnAccount) — требование
-- Google Play (Data safety / account deletion) для приложений с
-- регистрацией внутри приложения.
--
-- Точечный патч поверх уже работающей базы. Как применить: Supabase
-- Dashboard -> SQL Editor -> New query -> вставить весь файл -> Run.
-- Один раз.
-- =============================================================================

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Не авторизован';
  end if;

  delete from public.device_tokens where profile_id = auth.uid();
  delete from public.request_read_state where profile_id = auth.uid();
  delete from public.establishment_members where profile_id = auth.uid();

  update public.profiles
  set full_name = null,
      phone = null
  where id = auth.uid();
end;
$$;
