// send-booking-email
//
// Dispara os e-mails do fluxo de reserva (estilo Airbnb):
//   - "new_request"  -> confirmação pro solicitante + aviso pro anunciante
//                       (com link que abre o app pra aceitar/recusar)
//   - "accepted"     -> aviso de aprovação pro solicitante, com sugestões
//                       de outros ativos complementares (mesma
//                       especialidade + mesma cidade)
//   - "declined"     -> aviso de recusa pro solicitante, com alternativas
//                       parecidas com o que ele escolheu (mesma
//                       especialidade + faixa de preço + mesma cidade)
//
// Chamada pelo app via client.functions.invoke("send-booking-email", { body }).
// Usa a service role key (env padrão de toda Edge Function do Supabase,
// não precisa configurar) pra ler profiles/listings sem depender de RLS.
// Precisa do secret RESEND_API_KEY configurado no dashboard (Edge
// Functions -> Secrets) -- mesma conta do Resend já usada pro SMTP de
// recuperação de senha, mas uma chave própria pra essa função.

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const FROM = "Center Rent <suporte@centerrent.com.br>";
const APP_SCHEME = "centerrent://";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type EmailType = "new_request" | "accepted" | "declined";

interface ReqBody {
  type: EmailType;
  bookingId: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, bookingId } = (await req.json()) as ReqBody;
    if (!bookingId || !type) {
      return json({ error: "type e bookingId são obrigatórios" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: booking, error: bookingErr } = await supabase
      .from("bookings")
      .select("*")
      .eq("id", bookingId)
      .single();
    if (bookingErr || !booking) {
      return json({ error: "Reserva não encontrada" }, 404);
    }

    const { data: listing, error: listingErr } = await supabase
      .from("listings")
      .select("*")
      .eq("id", booking.listing_id)
      .single();
    if (listingErr || !listing) {
      return json({ error: "Anúncio não encontrado" }, 404);
    }

    const [{ data: renter }, { data: owner }] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", booking.renter_id).single(),
      supabase.from("profiles").select("*").eq("id", booking.owner_id).single(),
    ]);
    if (!renter || !owner) {
      return json({ error: "Perfil não encontrado" }, 404);
    }

    const ctx: EmailContext = { supabase, booking, listing, renter, owner };

    switch (type) {
      case "new_request":
        await Promise.all([
          sendEmail(renter.email, subjectRenterRequestSent(listing), renderRenterRequestSent(ctx)),
          sendEmail(owner.email, subjectOwnerNewRequest(listing), renderOwnerNewRequest(ctx)),
        ]);
        break;
      case "accepted": {
        const suggestions = await findComplementary(supabase, listing);
        await sendEmail(renter.email, subjectAccepted(listing), renderAccepted(ctx, suggestions));
        break;
      }
      case "declined": {
        const alternatives = await findAlternatives(supabase, listing);
        await sendEmail(renter.email, subjectDeclined(listing), renderDeclined(ctx, alternatives));
        break;
      }
      default:
        return json({ error: `Tipo desconhecido: ${type}` }, 400);
    }

    return json({ ok: true });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ─────────────────────────────────────────────────────────────
// Recomendações
// ─────────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;
// deno-lint-ignore no-explicit-any
type Row = any;

interface EmailContext {
  supabase: SupabaseClient;
  booking: Row;
  listing: Row;
  renter: Row;
  owner: Row;
}

/// Sugestões de ativos COMPLEMENTARES pra quem teve a reserva aceita --
/// mesma especialidade (equipamentos/salas que combinam com o que a
/// pessoa já vai usar) e mesma cidade, excluindo o próprio anúncio e
/// outros anúncios do mesmo dono (já reservado com ele). Se não achar
/// nada com os dois filtros, relaxa progressivamente (só especialidade,
/// depois só cidade, depois top-rated geral) -- sempre tenta devolver
/// até 3 resultados em vez de deixar o e-mail sem sugestão nenhuma.
async function findComplementary(supabase: SupabaseClient, listing: Row): Promise<Row[]> {
  const city = listing.address?.city;
  const specialties: string[] = listing.specialties ?? [];

  const attempts: Array<() => Promise<Row[]>> = [
    async () => {
      if (!specialties.length || !city) return [];
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .neq("owner_id", listing.owner_id)
        .overlaps("specialties", specialties)
        .eq("address->>city", city)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
    async () => {
      if (!specialties.length) return [];
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .overlaps("specialties", specialties)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
    async () => {
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
  ];

  for (const attempt of attempts) {
    const result = await attempt();
    if (result.length > 0) return result;
  }
  return [];
}

/// Alternativas PARECIDAS pra quem teve a reserva recusada -- mesma
/// especialidade + faixa de preço próxima (±40%) + mesma cidade. Mesma
/// cascata de fallback de findComplementary.
async function findAlternatives(supabase: SupabaseClient, listing: Row): Promise<Row[]> {
  const city = listing.address?.city;
  const specialties: string[] = listing.specialties ?? [];
  const price = Number(listing.price_per_hour ?? 0);
  const minPrice = price * 0.6;
  const maxPrice = price * 1.4;

  const attempts: Array<() => Promise<Row[]>> = [
    async () => {
      if (!specialties.length || !city) return [];
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .overlaps("specialties", specialties)
        .eq("address->>city", city)
        .gte("price_per_hour", minPrice)
        .lte("price_per_hour", maxPrice)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
    async () => {
      if (!specialties.length) return [];
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .overlaps("specialties", specialties)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
    async () => {
      const { data } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "active")
        .neq("id", listing.id)
        .order("rating", { ascending: false })
        .limit(3);
      return data ?? [];
    },
  ];

  for (const attempt of attempts) {
    const result = await attempt();
    if (result.length > 0) return result;
  }
  return [];
}

// ─────────────────────────────────────────────────────────────
// Resend
// ─────────────────────────────────────────────────────────────

async function sendEmail(to: string, subject: string, html: string) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM, to, subject, html }),
  });
  if (!res.ok) {
    console.error("Resend error:", await res.text());
  }
}

// ─────────────────────────────────────────────────────────────
// Formatação
// ─────────────────────────────────────────────────────────────

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "long", timeZone: "America/Sao_Paulo" });
}
function fmtTime(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit", timeZone: "America/Sao_Paulo" });
}
function fmtMoney(n: number): string {
  return `R$ ${n.toFixed(0)}`;
}
function esc(s: string): string {
  return (s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// ─────────────────────────────────────────────────────────────
// Subjects
// ─────────────────────────────────────────────────────────────

const subjectRenterRequestSent = (l: Row) => `Solicitação enviada — ${l.title}`;
const subjectOwnerNewRequest = (l: Row) => `Nova solicitação de reserva — ${l.title}`;
const subjectAccepted = (l: Row) => `Reserva confirmada! — ${l.title}`;
const subjectDeclined = (l: Row) => `Sobre sua solicitação — ${l.title}`;

// ─────────────────────────────────────────────────────────────
// Shell (mesmo estilo visual do e-mail de redefinir senha:
// logo real, cores #7F68C1 / #DCF289, card branco arredondado)
// ─────────────────────────────────────────────────────────────

const LOGO_URL =
  "https://vdfcbbycsrrdogtqyosp.supabase.co/storage/v1/object/public/email-assets/centerrent-logo@3x.png";

function shell(opts: {
  heroIcon: string; // URL do ícone (mesmo padrão do lock-icon.png)
  heading: string;
  subtext: string;
  body: string; // HTML já pronto (parágrafos, cards de sugestão, etc.)
  ctaLabel?: string;
  ctaHref?: string;
  footerNote?: string;
}): string {
  const cta = opts.ctaLabel && opts.ctaHref
    ? `
      <tr>
        <td class="cr-pad" style="padding: 24px 40px 8px; text-align:center;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto;">
            <tr>
              <td class="cr-button-cell" style="border-radius:14px; background-color:#7F68C1;">
                <a href="${opts.ctaHref}" class="cr-button" target="_blank"
                   style="display:inline-block; padding:16px 40px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size:16px; font-weight:700; color:#FFFFFF; text-decoration:none; border-radius:14px;">
                  ${opts.ctaLabel}
                </a>
              </td>
            </tr>
          </table>
        </td>
      </tr>`
    : "";

  return `<!DOCTYPE html>
<html lang="pt-BR" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<meta name="color-scheme" content="light" />
<meta name="supported-color-schemes" content="light" />
<title>${esc(opts.heading)}</title>
<style>
  body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
  table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
  img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
  body { margin: 0; padding: 0; width: 100% !important; height: 100% !important; }
  a.cr-button { transition: background-color .15s ease; }
  a.cr-button:hover { background-color: #5E4D9A !important; }
  @media screen and (max-width: 600px) {
    .cr-container { width: 100% !important; }
    .cr-pad { padding-left: 20px !important; padding-right: 20px !important; }
    .cr-hero-pad { padding: 28px 20px !important; }
    .cr-heading { font-size: 22px !important; line-height: 28px !important; }
    .cr-button-cell a { display: block !important; width: 100% !important; box-sizing: border-box; }
  }
</style>
</head>
<body style="margin:0; padding:0; background-color:#F8FAFC;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F8FAFC;">
    <tr>
      <td align="center" style="padding: 40px 16px;">
        <table role="presentation" class="cr-container" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px; max-width:600px;">
          <tr>
            <td class="cr-pad" style="padding: 0 8px 28px; text-align:center;">
              <img src="${LOGO_URL}" width="140" height="79" alt="Center Rent"
                   style="display:inline-block; border:0; outline:none; text-decoration:none; height:auto; max-width:140px;" />
            </td>
          </tr>
          <tr>
            <td style="background-color:#FFFFFF; border-radius:20px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td class="cr-hero-pad" style="background-color:#F1EEFA; border-radius:20px 20px 0 0; padding: 36px 40px 32px;">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <td style="width:52px; vertical-align:top; padding-right:16px;">
                          <img src="${opts.heroIcon}" width="52" height="52" alt=""
                               style="display:block; border:0; outline:none; text-decoration:none; border-radius:14px;" />
                        </td>
                        <td style="vertical-align:top;">
                          <p class="cr-heading" style="margin:0 0 8px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 24px; line-height: 30px; font-weight: 800; color:#0F172A;">
                            ${esc(opts.heading)}
                          </p>
                          <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; line-height: 22px; color:#475569;">
                            ${opts.subtext}
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td class="cr-pad" style="padding: 28px 40px 8px;">
                    ${opts.body}
                  </td>
                </tr>
                ${cta}
                <tr>
                  <td class="cr-pad" style="padding: 28px 40px 36px; text-align:center;">
                    <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 13px; line-height: 20px; color:#94A3B8;">
                      ${opts.footerNote ?? "Dúvidas? Responda este e-mail que te ajudamos."}
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td class="cr-pad" style="padding: 28px 24px 0; text-align:center;">
              <p style="margin:0 0 6px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; line-height: 18px; color:#94A3B8;">
                © 2026 Center Rent. Todos os direitos reservados.
              </p>
              <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; line-height: 18px;">
                <a href="mailto:suporte@centerrent.com.br" style="color:#7F68C1; text-decoration:underline;">suporte@centerrent.com.br</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

// Card de detalhes da reserva (data/hora/valor), reaproveitado nos 4 e-mails
function bookingDetailsCard(booking: Row, listing: Row): string {
  const img = (listing.image_urls ?? [])[0];
  return `
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
           style="background-color:#F8FAFC; border-radius:14px; margin-bottom:20px;">
      <tr>
        ${img ? `
        <td style="width:72px; padding:16px 0 16px 16px; vertical-align:top;">
          <img src="${img}" width="64" height="64" alt=""
               style="display:block; border-radius:10px; object-fit:cover; width:64px; height:64px;" />
        </td>` : ""}
        <td style="padding:16px; vertical-align:top;">
          <p style="margin:0 0 6px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; font-weight:700; color:#0F172A;">
            ${esc(listing.title)}
          </p>
          <p style="margin:0 0 2px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 13px; color:#475569;">
            ${fmtDate(booking.start_date)} · ${fmtTime(booking.start_date)} — ${fmtTime(booking.end_date)}
          </p>
          <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 13px; color:#475569;">
            ${esc(listing.address?.neighborhood ?? "")}, ${esc(listing.address?.city ?? "")} · <strong style="color:#7F68C1;">${fmtMoney(Number(booking.total_amount))}</strong>
          </p>
        </td>
      </tr>
    </table>`;
}

// Grade de sugestões (usada em accepted e declined) -- cada card linka
// direto pro anúncio (centerrent://listing/{id}, já suportado por
// AppRouter.handleDeepLink), pra ir de "sugestão" a "reservar" em 1 toque.
function suggestionsGrid(title: string, listings: Row[]): string {
  if (!listings.length) return "";
  const cards = listings.map((l) => `
    <a href="${APP_SCHEME}listing/${l.id}" style="text-decoration:none;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
           style="border:1px solid #E2E8F0; border-radius:12px; margin-bottom:12px;">
      <tr>
        ${(l.image_urls ?? [])[0] ? `
        <td style="width:64px; padding:12px; vertical-align:top;">
          <img src="${l.image_urls[0]}" width="56" height="56" alt=""
               style="display:block; border-radius:8px; object-fit:cover; width:56px; height:56px;" />
        </td>` : ""}
        <td style="padding:12px 12px 12px 0; vertical-align:top;">
          <p style="margin:0 0 4px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; font-weight:700; color:#0F172A;">
            ${esc(l.title)}
          </p>
          <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; color:#94A3B8;">
            ${esc(l.address?.city ?? "")} · ${fmtMoney(Number(l.price_per_hour))}/hora ${l.rating ? `· ★ ${Number(l.rating).toFixed(1)}` : ""}
          </p>
        </td>
      </tr>
    </table>
    </a>`).join("");

  return `
    <p style="margin:8px 0 12px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; font-weight:700; color:#0F172A;">
      ${esc(title)}
    </p>
    ${cards}`;
}

// ─────────────────────────────────────────────────────────────
// Templates
// ─────────────────────────────────────────────────────────────

const ICON_CHECK =
  "https://vdfcbbycsrrdogtqyosp.supabase.co/storage/v1/object/public/email-assets/lock-icon.png";

function renderRenterRequestSent(ctx: EmailContext): string {
  return shell({
    heroIcon: ICON_CHECK,
    heading: "Solicitação enviada!",
    subtext: `Enviamos seu pedido de reserva para ${esc(ctx.owner.full_name || "o anunciante")}.`,
    body: `
      ${bookingDetailsCard(ctx.booking, ctx.listing)}
      <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; line-height: 22px; color:#0F172A;">
        Você vai receber um e-mail assim que ${esc(ctx.owner.full_name || "o anunciante")} responder à sua solicitação.
      </p>`,
    ctaLabel: "Acompanhar reserva",
    ctaHref: `${APP_SCHEME}booking/${ctx.booking.id}`,
  });
}

function renderOwnerNewRequest(ctx: EmailContext): string {
  return shell({
    heroIcon: ICON_CHECK,
    heading: "Nova solicitação de reserva",
    subtext: `${esc(ctx.renter.full_name || "Um usuário")} quer reservar seu anúncio.`,
    body: `
      ${bookingDetailsCard(ctx.booking, ctx.listing)}
      <p style="margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; line-height: 22px; color:#0F172A;">
        Abra o app pra ver os detalhes e aceitar ou recusar a solicitação.
      </p>`,
    ctaLabel: "Aceitar ou recusar",
    ctaHref: `${APP_SCHEME}booking/${ctx.booking.id}`,
    footerNote: "O link acima abre o Center Rent direto na tela da solicitação.",
  });
}

function renderAccepted(ctx: EmailContext, suggestions: Row[]): string {
  return shell({
    heroIcon: ICON_CHECK,
    heading: "Reserva confirmada!",
    subtext: `${esc(ctx.owner.full_name || "O anunciante")} aceitou sua solicitação.`,
    body: `
      ${bookingDetailsCard(ctx.booking, ctx.listing)}
      ${suggestionsGrid("Quem reservou isso também usa", suggestions)}`,
    ctaLabel: "Ver minha reserva",
    ctaHref: `${APP_SCHEME}booking/${ctx.booking.id}`,
  });
}

function renderDeclined(ctx: EmailContext, alternatives: Row[]): string {
  return shell({
    heroIcon: ICON_CHECK,
    heading: "Sua solicitação não foi aceita",
    subtext: `${esc(ctx.owner.full_name || "O anunciante")} não pôde aceitar sua reserva dessa vez.`,
    body: `
      ${bookingDetailsCard(ctx.booking, ctx.listing)}
      <p style="margin:0 0 8px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 15px; line-height: 22px; color:#0F172A;">
        Sem problemas — separamos opções parecidas com o que você procurava:
      </p>
      ${suggestionsGrid("Você também pode gostar de", alternatives)}`,
    ctaLabel: "Explorar espaços",
    ctaHref: `${APP_SCHEME}search`,
  });
}
