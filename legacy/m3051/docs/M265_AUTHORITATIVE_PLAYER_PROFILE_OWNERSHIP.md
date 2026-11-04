# M265 — Authoritative Player Profile / Ownership Persistence

M265 binds verified Account/Captain identity to one server-authoritative persistent player profile. Ownership instances, fleet/loadout references, wallet and progression are read-only client replicas until a production repository confirms a revision-bound idempotent transaction.

LOCAL remains preview-only. TEST and GLOBAL ownership are isolated. Equipped references must resolve to owned instances. No final capacity, wallet, progression, timeout or retry values are invented.
