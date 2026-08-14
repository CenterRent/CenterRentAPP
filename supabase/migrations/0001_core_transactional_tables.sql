-- ============================================================
-- Center Rent — cria as tabelas do núcleo transacional
-- ============================================================
-- Descoberto ao vivo em 14/08/2026: só existiam amenities,
-- listing_amenities, listings e profiles no banco. A migration antiga
-- (supabase_migration.sql, arquivo fora do repo) que definia bookings/
-- conversations/messages/reviews/notifications/referrals nunca chegou
-- a ser aplicada nesse projeto.
--
-- Este arquivo cria essas 6 tabelas do zero, já alinhadas 1:1 com o que
-- Core/Network/SupabaseManager.swift espera (ver structs BookingRow,
-- ConversationRow, MessageRow, NotificationRow, ReferralRow e os
-- Insert payloads de cada função) — sem isso, nada do Sprint 0 roda de
-- verdade contra o banco.
--
-- Rode no SQL Editor do projeto Center Rent:
-- https://supabase.com/dashboard/project/vdfcbbycsrrdogtqyosp/sql/new
-- ============================================================

-- reaproveita o trigger de updated_at já criado por supabase_listing_migration.sql
-- (public.set_updated_at) — se por algum motivo não existir, cria de novo.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ─────────────────────────────────────────────
-- 1. BOOKINGS
-- ─────────────────────────────────────────────
create table if not exists public.bookings (
  id             uuid primary key default gen_random_uuid(),
  listing_id     uuid not null references public.listings(id) on delete cascade,
  renter_id      uuid not null references auth.users(id) on delete cascade,
  owner_id       uuid not null references auth.users(id) on delete cascade,

  start_date     timestamptz not null,
  end_date       timestamptz not null,
  total_hours    numeric(6,2) not null default 0,
  total_amount   numeric(10,2) not null,
  platform_fee   numeric(10,2) not null default 0,

  status         text not null default 'pending'
                   check (status in ('pending','accepted','declined','confirmed','active','completed','cancelled')),
  renter_notes   text,

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists bookings_listing_id_idx on public.bookings(listing_id);
create index if not exists bookings_renter_id_idx  on public.bookings(renter_id);
create index if not exists bookings_owner_id_idx   on public.bookings(owner_id);
create index if not exists bookings_status_idx     on public.bookings(status);

drop trigger if exists bookings_updated_at on public.bookings;
create trigger bookings_updated_at
  before update on public.bookings
  for each row execute procedure public.set_updated_at();

alter table public.bookings enable row level security;

drop policy if exists "bookings_select_participant" on public.bookings;
create policy "bookings_select_participant"
  on public.bookings for select
  using (renter_id = auth.uid() or owner_id = auth.uid());

drop policy if exists "bookings_insert_renter" on public.bookings;
create policy "bookings_insert_renter"
  on public.bookings for insert
  with check (renter_id = auth.uid());

-- Locatário pode atualizar (ex: cancelar) e locador pode atualizar (aceitar/recusar) —
-- ambos limitados a reservas em que participam.
drop policy if exists "bookings_update_participant" on public.bookings;
create policy "bookings_update_participant"
  on public.bookings for update
  using (renter_id = auth.uid() or owner_id = auth.uid());


-- ─────────────────────────────────────────────
-- 2. CONVERSATIONS & MESSAGES
-- ─────────────────────────────────────────────
create table if not exists public.conversations (
  id               uuid primary key default gen_random_uuid(),
  listing_id       uuid references public.listings(id) on delete set null,
  renter_id        uuid not null references auth.users(id) on delete cascade,
  owner_id         uuid not null references auth.users(id) on delete cascade,
  last_message     text,
  last_message_at  timestamptz default now(),
  created_at       timestamptz not null default now()
);

create index if not exists conversations_renter_id_idx on public.conversations(renter_id);
create index if not exists conversations_owner_id_idx  on public.conversations(owner_id);

alter table public.conversations enable row level security;

drop policy if exists "conversations_select_participant" on public.conversations;
create policy "conversations_select_participant"
  on public.conversations for select
  using (renter_id = auth.uid() or owner_id = auth.uid());

drop policy if exists "conversations_insert_participant" on public.conversations;
create policy "conversations_insert_participant"
  on public.conversations for insert
  with check (renter_id = auth.uid() or owner_id = auth.uid());

drop policy if exists "conversations_update_participant" on public.conversations;
create policy "conversations_update_participant"
  on public.conversations for update
  using (renter_id = auth.uid() or owner_id = auth.uid());


create table if not exists public.messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references public.conversations(id) on delete cascade,
  sender_id        uuid not null references auth.users(id) on delete cascade,
  content          text not null,
  is_read          boolean not null default false,
  created_at       timestamptz not null default now()
);

create index if not exists messages_conversation_id_idx on public.messages(conversation_id);

alter table public.messages enable row level security;

drop policy if exists "messages_select_participant" on public.messages;
create policy "messages_select_participant"
  on public.messages for select
  using (exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and (c.renter_id = auth.uid() or c.owner_id = auth.uid())
  ));

drop policy if exists "messages_insert_sender" on public.messages;
create policy "messages_insert_sender"
  on public.messages for insert
  with check (sender_id = auth.uid());

drop policy if exists "messages_update_participant" on public.messages;
create policy "messages_update_participant"
  on public.messages for update
  using (exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and (c.renter_id = auth.uid() or c.owner_id = auth.uid())
  ));

-- Necessário pro realtime (onPostgresChange) entregar INSERTs aos assinantes.
alter publication supabase_realtime add table public.messages;


-- ─────────────────────────────────────────────
-- 3. REVIEWS
-- ─────────────────────────────────────────────
create table if not exists public.reviews (
  id           uuid primary key default gen_random_uuid(),
  booking_id   uuid not null references public.bookings(id) on delete cascade,
  author_id    uuid not null references auth.users(id) on delete cascade,
  target_id    uuid not null,   -- listing_id ou user_id, dependendo de target_type
  target_type  text not null check (target_type in ('listing','user')),
  rating       numeric(2,1) not null check (rating >= 1 and rating <= 5),
  comment      text,
  created_at   timestamptz not null default now()
);

create index if not exists reviews_target_idx on public.reviews(target_id, target_type);
create index if not exists reviews_booking_id_idx on public.reviews(booking_id);

alter table public.reviews enable row level security;

drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public"
  on public.reviews for select
  using (true);

drop policy if exists "reviews_insert_author" on public.reviews;
create policy "reviews_insert_author"
  on public.reviews for insert
  with check (author_id = auth.uid());


-- ─────────────────────────────────────────────
-- 4. NOTIFICATIONS
-- ─────────────────────────────────────────────
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  body        text,
  type        text,
  is_read     boolean not null default false,
  deep_link   text,
  created_at  timestamptz not null default now()
);

create index if not exists notifications_user_id_idx on public.notifications(user_id, is_read);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select
  using (user_id = auth.uid());

-- Precisa permitir insert de QUALQUER usuário autenticado, porque quem cria a
-- notificação é sempre a "outra parte" do evento (ex: locatário reserva ->
-- cria notificação PRO locador, não pra si mesmo).
drop policy if exists "notifications_insert_authenticated" on public.notifications;
create policy "notifications_insert_authenticated"
  on public.notifications for insert
  with check (auth.uid() is not null);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update
  using (user_id = auth.uid());


-- ─────────────────────────────────────────────
-- 5. REFERRALS / MGM
-- ─────────────────────────────────────────────
create table if not exists public.referrals (
  id             uuid primary key default gen_random_uuid(),
  referrer_id    uuid not null references auth.users(id) on delete cascade,
  referred_id    uuid references auth.users(id) on delete set null,
  referral_code  text not null unique,
  status         text not null default 'pending' check (status in ('pending','completed','rewarded')),
  reward_amount  numeric(10,2) default 0,
  created_at     timestamptz not null default now()
);

alter table public.referrals enable row level security;

drop policy if exists "referrals_select_own" on public.referrals;
create policy "referrals_select_own"
  on public.referrals for select
  using (referrer_id = auth.uid());

drop policy if exists "referrals_insert_own" on public.referrals;
create policy "referrals_insert_own"
  on public.referrals for insert
  with check (referrer_id = auth.uid());


-- ─────────────────────────────────────────────
-- 6. PROFILES — adiciona user_type se ainda não existir
-- ─────────────────────────────────────────────
-- (issue #14, Sprint 1: onboarding locador/locatário/ambos)
alter table public.profiles
  add column if not exists user_type text not null default 'renter'
    check (user_type in ('renter','owner','both'));
