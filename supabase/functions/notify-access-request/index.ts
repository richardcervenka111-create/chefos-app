// Sautero — email notification when someone new requests access (2026-07-15).
//
// Why this exists: the real blocker for a public trial is that Resend's free tier can only
// deliver email to the account owner's own verified address until a custom domain is verified
// (this is why non-Richard addresses can't receive their login code yet — see the "Email login
// pre cudzie adresy" item in status.html). Rather than wait on domain verification, Richard's
// call (2026-07-15): keep every new person funneled through the existing manual approval gate
// (access_requests / db/34_teams_access_gate.sql, already built), and make sure HE actually
// gets notified the moment someone new asks to join — today he had to remember to check the
// Admin tile himself. This function sends that notification, to his own address, which Resend's
// free tier can already deliver without any domain setup (same restriction that blocks
// everyone else's login code works IN OUR FAVOUR here, since the destination is his own
// account).
//
// This does NOT fix outside users receiving their own OTP login code — that's still open and
// needs either a verified Resend domain or switching to Supabase's built-in mailer. This only
// makes the existing manual-approval step actually reach Richard's inbox instead of requiring
// him to remember to check.
//
// Deploy (Richard, from a terminal with the Supabase CLI installed and logged in):
//   supabase secrets set RESEND_API_KEY=<your Resend API key — same one used for the OTP mailer setup, or create a new one at resend.com/api-keys>
//   supabase functions deploy notify-access-request

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const NOTIFY_EMAIL = 'richard.cervenka@icloud.com';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  try {
    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: { message: 'RESEND_API_KEY not set on this project — run supabase secrets set RESEND_API_KEY=... first.' } }), {
        status: 500, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    const { email } = await req.json();
    if (!email) {
      return new Response(JSON.stringify({ error: { message: 'Missing email in request body.' } }), {
        status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Sautero <onboarding@resend.dev>',
        to: [NOTIFY_EMAIL],
        subject: `Sautero — new access request: ${email}`,
        text: `${email} just requested access to Sautero.\n\nOpen the Admin tile in the app to approve or deny it.`,
      }),
    });

    if (!resendRes.ok) {
      const detail = await resendRes.text();
      return new Response(JSON.stringify({ error: { message: `Resend API error: ${detail}` } }), {
        status: 502, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: { message: String(err) } }), {
      status: 500, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
    });
  }
});
