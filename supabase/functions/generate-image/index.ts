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

// Google rotates image models for new users (22.7.: imagen-4.0-generate-001 came back 404
// "no longer available to new users"). Try candidates newest-first; the Gemini image model is
// the final fallback and uses a different API shape (generateContent + inlineData).
const IMAGEN_CANDIDATES = [
  'imagen-4.0-generate-002',
  'imagen-4.0-fast-generate-001',
  'imagen-3.0-generate-002',
];
const GEMINI_IMAGE_MODEL = 'gemini-2.5-flash-image';

// Per-image price (USD) so Admin → AI Usage can show what this feature costs, the same way
// claude-proxy logs token cost. Google bills image models per generated image (22.7. rates:
// gemini-2.5-flash-image ≈ $0.039, Imagen 4 ≈ $0.04). Unknown model → the flash-image rate.
const IMAGE_COST_USD: Record<string, number> = {
  'gemini-2.5-flash-image': 0.039,
  'imagen-4.0-generate-002': 0.04,
  'imagen-4.0-fast-generate-001': 0.02,
  'imagen-3.0-generate-002': 0.04,
};
const DEFAULT_IMAGE_COST_USD = 0.039;

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

    // Admin (service-role, no user JWT) client for logging usage past RLS — same pattern as
    // claude-proxy. Every successful image is written to ai_usage so Admin → AI Usage can show
    // this feature's cost. Best-effort: a logging hiccup must never cost the user their image.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    async function logImageUsage(model: string) {
      try {
        const { data: profile } = await adminClient
          .from('profiles').select('kitchen_id').eq('id', user!.id).maybeSingle();
        await adminClient.from('ai_usage').insert({
          user_id: user!.id,
          kitchen_id: profile?.kitchen_id ?? null,
          feature: 'recipe_photo',
          model,
          input_tokens: 0,
          output_tokens: 0,
          cost_usd: IMAGE_COST_USD[model] ?? DEFAULT_IMAGE_COST_USD,
        });
      } catch (_e) { /* logging is best-effort, never fail the image over it */ }
    }

    if (!GEMINI_API_KEY) {
      return json(500, { error: { message: 'GEMINI_API_KEY is not set — add it under Project Settings → Edge Functions → Secrets.' } });
    }

    const { prompt } = await req.json();
    if (!prompt || typeof prompt !== 'string' || prompt.length > 4000) {
      return json(400, { error: { message: 'Send a { prompt } string (max 4000 chars).' } });
    }

    const failures: string[] = [];

    // 1) Imagen candidates, newest first (predict API)
    for (const model of IMAGEN_CANDIDATES) {
      const resp = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:predict`,
        {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
          body: JSON.stringify({
            instances: [{ prompt }],
            parameters: { sampleCount: 1, aspectRatio: '4:3' }
          })
        }
      );
      if (resp.ok) {
        const data = await resp.json();
        const pred = data.predictions && data.predictions[0];
        if (pred && pred.bytesBase64Encoded) {
          await logImageUsage(model);
          return json(200, { imageBase64: pred.bytesBase64Encoded, mimeType: pred.mimeType || 'image/png', model });
        }
        failures.push(`${model}: ok but no image`);
      } else {
        failures.push(`${model}: ${resp.status}`);
        // non-404 (e.g. 429 quota, 400 safety) — no point trying older models for those
        if (resp.status !== 404) {
          const detail = await resp.text();
          return json(resp.status, { error: { message: `Image call failed (${resp.status}, ${model}): ${detail.slice(0, 300)}` } });
        }
      }
    }

    // 2) Fallback: Gemini image model (generateContent + inlineData shape)
    const gResp = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_IMAGE_MODEL}:generateContent`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': GEMINI_API_KEY },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseModalities: ['IMAGE'] }
        })
      }
    );
    if (gResp.ok) {
      const gData = await gResp.json();
      const parts = gData.candidates?.[0]?.content?.parts || [];
      const imgPart = parts.find((p: { inlineData?: { data?: string } }) => p.inlineData && p.inlineData.data);
      if (imgPart) {
        await logImageUsage(GEMINI_IMAGE_MODEL);
        return json(200, { imageBase64: imgPart.inlineData.data, mimeType: imgPart.inlineData.mimeType || 'image/png', model: GEMINI_IMAGE_MODEL });
      }
      failures.push(`${GEMINI_IMAGE_MODEL}: ok but no image part`);
    } else {
      failures.push(`${GEMINI_IMAGE_MODEL}: ${gResp.status} ${(await gResp.text()).slice(0, 200)}`);
    }

    return json(502, { error: { message: `No image model worked — tried: ${failures.join(' | ')}` } });
  } catch (err) {
    return json(500, { error: { message: (err as Error).message || 'generate-image failed' } });
  }
});
