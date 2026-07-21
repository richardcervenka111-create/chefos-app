// Sautero — "You've been made a Company Admin" email (2026-07-21, Richard: dedicated wording,
// not the generic magic-link mail). Sends a branded Resend email whose button is a real magic
// link: one tap logs the person in and lands them on the in-app accept step (?invite=), where
// they name their own restaurant. Their personal recipes stay private — this only gives them a
// new company/team.
//
// sautero.ch is a verified Resend domain, so this can deliver to any recipient (unlike the old
// onboarding@resend.dev sender, which only reached Richard's own inbox).
//
// Deploy (Richard, from a terminal with the Supabase CLI installed + logged in):
//   supabase functions deploy notify-company-offer
// RESEND_API_KEY is already set (from notify-access-request). SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are injected into every edge function automatically.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.86.0';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  try {
    if (!RESEND_API_KEY) return json({ error: { message: 'RESEND_API_KEY not set on this project.' } }, 500);

    const { email, inviteUrl } = await req.json();
    if (!email || !inviteUrl) return json({ error: { message: 'Missing email or inviteUrl.' } }, 400);

    // A magic link so one tap logs them in and drops them on the ?invite= accept step.
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: linkData, error: linkErr } = await admin.auth.admin.generateLink({
      type: 'magiclink',
      email,
      options: { redirectTo: inviteUrl },
    });
    if (linkErr) return json({ error: { message: 'generateLink failed: ' + linkErr.message } }, 500);
    const actionLink = linkData?.properties?.action_link || inviteUrl;

    const html = `
<div style="margin:0;padding:0;background:#0A1A2F;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Arial,sans-serif;">
  <div style="max-width:520px;margin:0 auto;padding:32px 24px;color:#FFFFFF;">
    <div style="font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:#34F7D7;font-weight:700;">Kitchen Notebook</div>
    <div style="font-size:30px;font-weight:700;margin:2px 0 24px;font-family:Georgia,serif;">Sautero</div>
    <div style="background:#122845;border:1px solid #223d57;border-radius:16px;padding:24px;">
      <div style="font-size:20px;font-weight:700;margin-bottom:10px;">🎉 You've been made a Company Admin</div>
      <p style="font-size:15px;line-height:1.6;color:#dfe7f0;margin:0 0 8px;">
        You've been given the <b>Company Admin</b> role on Sautero — you can now run your own restaurant / company here.
      </p>
      <p style="font-size:15px;line-height:1.6;color:#dfe7f0;margin:0 0 20px;">
        Tap the button below to accept and name your restaurant. Your personal recipes stay private — this only sets up your company.
      </p>
      <a href="${actionLink}" style="display:inline-block;background:#34F7D7;color:#0A1A2F;font-weight:700;font-size:15px;text-decoration:none;padding:14px 22px;border-radius:12px;">Accept &amp; set up my restaurant</a>
      <p style="font-size:12px;line-height:1.5;color:#9C949E;margin:20px 0 0;">
        If the button doesn't work, you can also just open the app and tap the notification in your Profile. This link is single-use and expires — don't share it.
      </p>
    </div>
    <p style="font-size:11px;color:#6b7787;margin:20px 0 0;text-align:center;">Sautero · app.sautero.ch</p>
  </div>
</div>`;

    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'Sautero <noreply@sautero.ch>',
        to: [email],
        subject: "You're now a Company Admin on Sautero",
        html,
      }),
    });
    const resendBody = await resendRes.json();
    if (!resendRes.ok) return json({ error: { message: 'Resend error: ' + JSON.stringify(resendBody) } }, 502);

    return json({ ok: true, id: resendBody?.id });
  } catch (e) {
    return json({ error: { message: String((e as Error)?.message || e) } }, 500);
  }
});
