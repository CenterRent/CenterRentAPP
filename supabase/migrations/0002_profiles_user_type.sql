-- Sprint 1 (issue #14) — tipo de usuário (locador/locatário/ambos)
--
-- Idempotente por padrão: seguro rodar mesmo que a coluna já exista na
-- prática (verificado ao vivo em 2026-08 que profiles.user_type já
-- existia no projeto — este migration só documenta e garante formalmente
-- o que já estava lá, com a CHECK constraint e o índice).

alter table public.profiles
  add column if not exists user_type text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_user_type_check'
  ) then
    alter table public.profiles
      add constraint profiles_user_type_check
      check (user_type in ('renter', 'owner', 'both'));
  end if;
end $$;

create index if not exists profiles_user_type_idx on public.profiles(user_type);
