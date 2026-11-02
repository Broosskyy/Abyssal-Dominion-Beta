# M264 — Auth / Account / Persistent Repository Integration Boundary

M264 deepens the Online Alpha path at the first durable boundary: provider/server verified identity and revision-guarded persistent account state. LOCAL remains preview-only and cannot become a live account. Account/Captain IDs are immutable after verification. Repository commits require server confirmation, expected revision and idempotency/transaction identity. TEST and GLOBAL never share profile authority.

Production adapters, database, token issuance/refresh, linking conflicts, migrations and native provider QA remain open. No final timeout, retry, token lifetime or cache values are invented.
