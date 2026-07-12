-- ChefOS — tighten permissions on the signup trigger function
-- Addresses Supabase's Security Advisor warnings "Public/Signed-In Users Can Execute
-- SECURITY DEFINER Function" for handle_new_user(). The function is only meant to run
-- automatically as part of account signup (via the trigger) — this makes sure nobody
-- can call it directly themselves.

revoke execute on function public.handle_new_user() from public, authenticated, anon;
