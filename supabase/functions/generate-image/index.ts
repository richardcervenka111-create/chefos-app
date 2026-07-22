// Sautero — server-side recipe photo generation (2026-07-22, Richard picked Google Imagen).
//
// Generates a realistic, illustrative dish photo from a recipe's own text via the Gemini API
// (Imagen). The GEMINI_API_KEY lives ONLY here as an Edge Function secret — never in the
// browser (same key-hygiene rule as claude-proxy). Caller must be a signed-in Sautero user.
//
// SETUP (Richard, one time):
//   1. Google AI Studio (aistudio.google.com) → Get API key → create key.
//   2. Supabase Dashboard → Project Settings → Edge Functions → Secrets →
//      add GEMINI_API_KEY = <the key>.
//   3. Deploy:  supabase functions deploy generate-image
//      (or paste this file into Dashboard → Edge Functions → New function → generate-image).
//
// The app calls this behind the `recipe_photo_gen` feature flag (dark until Richard approves).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';

const IMAGEN_MODEL = 'imagen-4.0-generate-001';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status, headers: { ...CORS_HEADERS, 'content-type': 'application/json' }
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });

  try {
    // Signed-in Sautero users only — a stranger must not be able to burn image credits.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json(401, { error: { message: 'Missing Authorization header.' } });
    const supabaseAsUser = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } }
    });
    const { data: { user }, error: userError } = await supabaseAsUser.auth.getUser();
    if (userError || !user) return json(401, { error: { message: 'Not signed in.' } });

    if (!GEMINI_API_KEY) {
      return json(500, { error: { message: 'GEMINI_API_KEY is not set — add it under Project Settings → Edge Functions → Secrets.' } });
    }

    const { prompt } = await req.json();
    if (!prompt || typeof prompt !== 'string' || prompt.length > 4000) {
      return json(400, { error: { message: 'Send a { prompt } string (max 4000 chars).' } });
    }

    const resp = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${IMAGEN_MODEL}:predict`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
        body: JSON.stringify({
          instances: [{ prompt }],
          parameters: { sampleCount: 1, aspectRatio: '4:3' }
        })
      }
    );
    if (!resp.ok) {
      const detail = await resp.text();
      return json(resp.status, { error: { message: `Imagen call failed (${resp.status}): ${detail.slice(0, 400)}` } });
    }
    const data = await resp.json();
    const pred = data.predictions && data.predictions[0];
    if (!pred || !pred.bytesBase64Encoded) {
      return json(502, { error: { message: 'Imagen returned no image — try again or adjust the recipe text.' } });
    }
    return json(200, { imageBase64: pred.bytesBase64Encoded, mimeType: pred.mimeType || 'image/png' });
  } catch (err) {
    return json(500, { error: { message: (err as Error).message || 'generate-image failed' } });
  }
});
