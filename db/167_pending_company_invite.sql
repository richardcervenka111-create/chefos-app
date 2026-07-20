-- db/167: pending_company_invite — a company-admin OFFER waiting for the person to accept.
--
-- Richard, 21.7.2026: granting Company Admin must NOT silently move someone into a company. It
-- creates an OFFER: the person gets a welcome email AND a notification in their own Profile, and
-- only when THEY accept (from the profile banner or the email link) are they moved in + asked to
-- name their restaurant. This column holds the invite id of that pending offer; it is cleared the
-- moment the offer is accepted (either path). Purely additive — nothing about existing kitchen/
-- team/permission logic changes.
alter table profiles add column if not exists pending_company_invite uuid;
