# M254 — Mail / Notifications / Claims / Rejoin Communication

M254 closes the explicit mail/inbox gap in the social convergence surface without pretending a live backend exists.

- Server-replica only for delivered mail, notifications and claim receipts.
- Mail supports event/ranking rewards, compensation, promotions and support use cases.
- Claims require request/transaction IDs and remain idempotent across timeout/reconnect.
- Critical HUD notices are transient and server-published only; normal notifications never create permanent HUD spam.
- Rejoin/maintenance/version/server-incident communication uses explicit presentation states.
- Local development does not fabricate mail, claimable rewards, notifications, read sync or receipts.
- Final reward values, expiry windows, campaign segmentation and production delivery are intentionally not invented.
