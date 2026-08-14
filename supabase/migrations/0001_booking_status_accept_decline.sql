-- ============================================================
-- Amplia bookings.status para suportar aceitar/recusar (issue #7)
-- ============================================================
-- Contexto: a migration original (supabase_migration.sql, fora do repo)
-- só permitia 'pending','confirmed','cancelled','completed','disputed'.
-- O app (Booking.BookingStatus, Core/Models/Models.swift) já espera um
-- ciclo mais rico: pending -> accepted/declined -> confirmed -> active
-- -> completed, com cancelled à parte. Sem essa migration, o app tentar
-- salvar status='accepted'/'declined' falha com violação da CHECK
-- constraint.
--
-- Rode isso no SQL Editor do projeto Center Rent
-- (https://supabase.com/dashboard/project/vdfcbbycsrrdogtqyosp/sql/new)
-- antes de testar aceitar/recusar reserva.
--
-- Aditivo e seguro: só amplia os valores permitidos, não altera dados
-- existentes nem remove nada.
-- ============================================================

DO $$
DECLARE
    existing_constraint text;
BEGIN
    SELECT con.conname INTO existing_constraint
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_attribute att ON att.attrelid = rel.oid AND att.attnum = ANY(con.conkey)
    WHERE rel.relname = 'bookings'
      AND con.contype = 'c'
      AND att.attname = 'status';

    IF existing_constraint IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.bookings DROP CONSTRAINT %I', existing_constraint);
    END IF;
END $$;

ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check
    CHECK (status IN ('pending','accepted','declined','confirmed','active','completed','cancelled'));
