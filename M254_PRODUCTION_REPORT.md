# Abyssal Dominion — M254 Production Report

## Scope
M254 adds the V3.8 Mail / Notifications / Claims convergence layer and rejoin communication polish.

## Delivered
- Server-authoritative read-only Mail/Notification/Claim replica.
- Event/ranking reward, compensation, promotion and support mail purposes.
- Idempotent request/transaction claim boundary; reconnect/timeouts cannot be interpreted as duplicate grants.
- No local fake inbox, fake claimable rewards, fake receipts or fake live notices.
- Command Deck integration under Social plus explicit rejoin communication under Online/Systemstatus.
- Admin schemas for mail, notification and compensation definitions.
- Continuous UI polish: critical communication is transient/contextual; ordinary notifications stay out of the gameplay HUD.

## Authority
Delivery, expiry, segmentation, read sync, claim eligibility, settlement, receipts and compensation remain server-owned. Local dismissal/filtering is presentation-only.

## Remaining
Connected notification/mail delivery, production claim/compensation ledger, push/e-mail delivery integration, native UX/network QA.
