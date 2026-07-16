// ChefOS — server-side Claude proxy (2026-07-13).
//
// Why this exists: every AI feature in app/index.html used to call
// https://api.anthropic.com/v1/messages directly from the browser, with the user's own
// Anthropic API key attached as a header. That key was then readable by anyone with access to
// the device's dev tools/network tab — a real risk flagged in the backlog v2 review. This
// function moves the actual API call server-side: the browser sends it the request body
// (model/tools/messages, everything except the key), this function looks up the calling user's
// own key from `user_settings` (server-side only, using the service-role key — never exposed to
// the browser), and forwards the call to Anthropic. The per-user "bring your own key" model is
// preserved on purpose (each user still pays for their own AI usage) — this only fixes where
// the key lives, not who owns it.
//
// Deploy (Richard, from a terminal with the Supabase CLI installed and logged in):
//   supabase functions deploy claude-proxy
// No new secrets needed — this function reads each user's key from the database, not from an
// environment variable. It does need the project's own service-role key, which Supabase
// injects automatically into every Edge Function as SUPABASE_SERVICE_ROLE_KEY — nothing to
// configure by hand.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// AI credit balance (Richard, 16.7. — db/102): Personal accounts pay a CHF amount, get 70% of
// it as usable credit (ChefOS keeps ~30% margin), and every real call here deducts its actual
// Anthropic cost from that balance. Prices are per Anthropic's published per-million-token
// rates for the models ChefOS actually calls (see app/index.html's callClaudeXxx() functions).
// Fixed USD->CHF rate, same "not live FX" convention as the app's own CURRENCY_INFO table.
const MODEL_PRICING_USD_PER_MILLION: Record<string, { input: number; output: number }> = {
  'claude-sonnet-5': { input: 3, output: 15 },
  'claude-haiku-4-5-20251001': { input: 1, output: 5 },
  'claude-opus-4-8': { input: 5, output: 25 },
};
const USD_TO_CHF = 0.87;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  try {
    // Identify the calling user from their own auth token (automatically attached by
    // supabase-js's `functions.invoke()` on the client) — this is what lets us look up
    // *their* key, and also what stops a stranger with no ChefOS account from calling this
    // function at all and burning API credits for free.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: { message: 'Missing Authorization header.' } }), {
        status: 401, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    const supabaseAsUser = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } }
    });
    const { data: { user }, error: userError } = await supabaseAsUser.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: { message: 'Not signed in.' } }), {
        status: 401, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    // Service-role client (bypasses RLS) purely to read this one user's own stored key —
    // never sent back to the browser, only used for the outgoing Anthropic call below.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Testing-mode kill switch (Richard, 16.7. — db/103): while ON, every device gets unlimited
    // AI regardless of account type or credit — same as if everyone were already topped up.
    // Toggled from Admin (openAiTestingMode() in app/index.html), Head Admin only.
    const { data: config } = await adminClient
      .from('app_config')
      .select('ai_unlimited_testing_mode')
      .eq('id', 1)
      .maybeSingle();
    const testingModeOn = !!config?.ai_unlimited_testing_mode;

    // AI credit gate for Personal accounts (bod 8, 16.7. — db/102 ai_credit_chf). The app's own
    // callClaudeAPI() already refuses to call this function client-side, but that's trivially
    // bypassable by anyone calling this endpoint directly — this is the real enforcement point.
    // Fails OPEN on a lookup error (same reasoning as every other gate in this project: a
    // migration not yet run, or a transient DB error, must never be what blocks someone from
    // using a feature they're entitled to). Company accounts are never metered/charged.
    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('account_type, ai_credit_chf')
      .eq('id', user.id)
      .maybeSingle();
    const isPersonal = !profileError && profile?.account_type === 'personal';

    // Share-with-ChefOS grant (Richard, 17.7.): AI help on a recipe the user agreed to share
    // with the ChefOS library is free — skip the credit gate AND the metering for this call.
    // HONEST NOTE: the flag is client-declared, so a determined user could set it on any call
    // to get free AI. Accepted for the pre-trial phase (the blast radius is one free call, and
    // shared recipes are curated by Richard, so a fake "share" earns nothing else); tighten to
    // a server-issued one-time voucher before the public trial if abuse ever shows up in the
    // usage numbers. The marker is STRIPPED before forwarding to Anthropic.
    const rawBody = await req.text();
    let parsedBody: Record<string, unknown> | null = null;
    try { parsedBody = JSON.parse(rawBody); } catch (_e) { /* forwarded as-is below */ }
    const shareGrant = parsedBody?._share_grant === 'recipe_chefos';
    if (shareGrant && parsedBody) delete parsedBody._share_grant;
    const body = shareGrant && parsedBody ? JSON.stringify(parsedBody) : rawBody;

    if (!testingModeOn && !shareGrant && isPersonal && !(Number(profile?.ai_credit_chf) > 0)) {
      return new Response(JSON.stringify({ error: { message: 'Your AI credit is used up. Ask your admin to top it up (Admin Directory).' } }), {
        status: 402, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    // Central key model (Richard, 16.7.): ALL AI calls run on ChefOS's own Anthropic key —
    // the ANTHROPIC_API_KEY project secret (set once via `supabase secrets set`). Nobody has
    // to bring their own key anymore; who's ALLOWED to use AI is governed entirely by the
    // credit/testing-mode gate above (Personal accounts pay → credit with the agreed margins).
    // A user's own stored key (the old BYOK model) still works as a fallback if the secret
    // isn't set, so nothing breaks between deploying this and setting the secret.
    const centralKey = Deno.env.get('ANTHROPIC_API_KEY') || '';
    let apiKey = centralKey;
    if (!apiKey) {
      const { data: settings } = await adminClient
        .from('user_settings')
        .select('anthropic_api_key')
        .eq('user_id', user.id)
        .maybeSingle();
      apiKey = settings?.anthropic_api_key || '';
    }
    if (!apiKey) {
      return new Response(JSON.stringify({ error: { message: 'AI is not configured yet — ask your admin (no API key available for this account).' } }), {
        status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    // Pass the request straight through — model/max_tokens/tools/tool_choice/messages are
    // whatever the app's own callClaudeXxx() function built, unchanged (body was already read
    // above for the share-grant check; only the marker was stripped).
    const requestedModel = (parsedBody?.model as string) || '';

    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body,
    });

    const responseText = await anthropicRes.text();

    // Deduct the real cost of this call from the Personal account's credit balance. Skipped
    // entirely during testing mode — nothing to meter while it's unlimited for everyone.
    // Best-effort and never blocks the response — a metering hiccup shouldn't cost someone
    // their answer they already paid Anthropic-side for via this same request.
    if (!testingModeOn && !shareGrant && isPersonal && anthropicRes.ok) {
      try {
        const usage = JSON.parse(responseText)?.usage;
        const pricing = MODEL_PRICING_USD_PER_MILLION[requestedModel];
        if (usage && pricing) {
          const costUsd = (Number(usage.input_tokens || 0) / 1_000_000) * pricing.input
            + (Number(usage.output_tokens || 0) / 1_000_000) * pricing.output;
          const costChf = costUsd * USD_TO_CHF;
          if (costChf > 0) {
            await adminClient
              .from('profiles')
              .update({ ai_credit_chf: Math.max(0, Number(profile?.ai_credit_chf || 0) - costChf) })
              .eq('id', user.id);
          }
        }
      } catch (_e) { /* metering is best-effort, never fail the actual response over it */ }
    }

    return new Response(responseText, {
      status: anthropicRes.status,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: { message: String(err) } }), {
      status: 500, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
    });
  }
});
