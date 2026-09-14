-- Descoberto ao vivo (14/09/2026): a tabela profiles real no banco NAO
-- tinha varias colunas que UserProfile (Core/Models/Models.swift) sempre
-- assumiu que existiam -- mesma classe de problema ja visto com
-- bookings/conversations/etc em 0001 (schema assumido de um arquivo
-- antigo/nunca aplicado). Confirmado via curl direto no REST API:
--
--   real:  id, email, full_name, display_name, phone_number,
--          profile_image_url, bio, user_type, is_verified_owner,
--          phone_verified, onboarding_complete, rating, total_reviews,
--          created_at, updated_at
--
--   faltando (usadas pelo app -- verificacao de CRO, sistema de
--   indicacao -- ambos com UI ja construida, por isso ADICIONAR as
--   colunas em vez de arrancar os campos do modelo):
--          specialty, registration_number, registration_state,
--          phone_verification_attempts, verification_status,
--          verification_document_url, referral_code, referred_by,
--          is_active
--
-- Ficou invisivel ate agora porque:
--  1) decode (fetchProfile) falhava silenciosamente pra qualquer coluna
--     ausente, e signIn/signUp/checkSession sempre capturavam o erro e
--     caiam num UserProfile.stub() -- sem crash visivel, so dado errado.
--  2) updateProfile nunca tinha sido exercitado de verdade antes desta
--     sessao (EditProfileView era 100% mockada, issue #23).
--
-- display_name/is_verified_owner/onboarding_complete/rating/
-- total_reviews (colunas reais que o modelo Swift NAO conhece) ficam de
-- fora por enquanto -- decode ignora chaves JSON extras sem erro, entao
-- nao bloqueiam nada; mapear isso e trabalho futuro se algo precisar.

alter table public.profiles
  add column if not exists specialty                   text not null default '',
  add column if not exists registration_number          text not null default '',
  add column if not exists registration_state            text not null default '',
  add column if not exists phone_verification_attempts  integer not null default 0,
  add column if not exists verification_status          text not null default 'not_submitted',
  add column if not exists verification_document_url    text,
  add column if not exists referral_code                text not null default '',
  add column if not exists referred_by                  text,
  add column if not exists is_active                    boolean not null default true;

-- referral_code precisa ser unico por usuario -- ADD COLUMN DEFAULT ''
-- preenche todo mundo com o mesmo valor, backfill abaixo gera um por id.
update public.profiles
  set referral_code = upper(substr(id::text, 1, 8))
  where referral_code = '';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_referral_code_key'
  ) then
    alter table public.profiles
      add constraint profiles_referral_code_key unique (referral_code);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_verification_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_verification_status_check
      check (verification_status in ('not_submitted', 'pending_verification', 'verified', 'rejected'));
  end if;
end $$;
