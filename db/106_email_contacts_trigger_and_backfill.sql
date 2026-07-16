-- ChefOS — make email_contacts reliable (Richard, 16.7.): patriklachky@gmail.com was approved
-- but never showed up in Email Contacts — the same class of gap as the paulapanizzon@gmail.com
-- miss from 15.7. (back then blamed on a policy fixed by db/86; this happening AGAIN means the
-- real cause is that the client-side upsert in renderTeamGate() is only best-effort — any
-- transient error at the exact moment of first sign-in silently drops the record forever, with
-- nothing logged anywhere Richard would see).
--
-- Real fix: move this server-side. A trigger on access_requests INSERT can't silently fail the
-- way a client-side upsert.then(console.error) can — it either succeeds as part of the same
-- transaction or the access_requests insert itself fails loudly. Plus a one-time backfill for
-- anyone already missing (not just this one person — catches every historical gap in one go).

create or replace function _sync_email_contact_from_access_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into email_contacts (email, source, status)
  values (lower(new.email), 'access_request', 'new')
  on conflict (email, source) do nothing;
  return new;
end;
$$;

drop trigger if exists on_access_request_sync_email_contact on access_requests;
create trigger on_access_request_sync_email_contact
  after insert on access_requests
  for each row execute function _sync_email_contact_from_access_request();

-- One-time backfill — catches patriklachky@gmail.com and anyone else already missing.
insert into email_contacts (email, source, status)
select lower(ar.email), 'access_request', 'new'
from access_requests ar
where not exists (
  select 1 from email_contacts ec where ec.email = lower(ar.email) and ec.source = 'access_request'
)
on conflict (email, source) do nothing;
