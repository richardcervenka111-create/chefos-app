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
    const { data: settings } = await adminClient
      .from('user_settings')
      .select('anthropic_api_key')
      .eq('user_id', user.id)
      .maybeSingle();

    const apiKey = settings?.anthropic_api_key;
    if (!apiKey) {
      return new Response(JSON.stringify({ error: { message: 'No Anthropic API key on file for this account. Add one under Photo-scan settings first.' } }), {
        status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
      });
    }

    // Pass the request straight through — model/max_tokens/tools/tool_choice/messages are
    // whatever the app's own callClaudeXxx() function built, unchanged.
    const body = await req.text();

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
