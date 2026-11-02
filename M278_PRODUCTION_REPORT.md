# M278 Production Report — Reward Inbox / Claim Queue / Overflow / Expiry

Master basis: V3.8. Continues M277 without replacing M254 mail, M266 atomic settlement, M276 roll integrity or M277 reward receipt/delivery authority.

## Implemented
- `M278AuthoritativeRewardInboxRuntime` as fail-closed server-replica boundary.
- Multiple pending reward inbox entries linked to existing M277 receipt/transaction/idempotency identity.
- Claim queue intents with inbox/queue revision guards and zero client value authority.
- Capacity overflow states, blocked delivery, server-authorized M254/M277 mail fallback continuity.
- Server-owned expiry/retention/revocation state; client cannot extend or reactivate expired rewards.
- Server-authorized compensation/recovery state with audit/idempotency expectations and M266-only durable settlement.
- Command Deck Online & Systemstatus cards; no new main menu or permanent debug HUD.
- Admin/No-Code policy definitions and convergence evidence.
- TEST/GLOBAL isolation retained.

## Intentionally unset
Final inbox capacity, batch size, processing rate, overflow retention, expiry/grace windows, compensation thresholds/values and recovery retry/backoff remain unset until measured and balanced.

## Production gaps
Production durable inbox repository/queue worker, scheduler, M254/M277/M266 backend integration, concurrency/idempotency enforcement and native disconnect/full-capacity/expiry/double-claim/load QA remain open.
