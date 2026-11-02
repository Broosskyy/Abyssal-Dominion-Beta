# M247 — Bazaar / Player Trading Foundation

Master basis: V3.8 Economy & Marketplace Bible §§250–253 plus MMO authority/transaction rules.

M247 promotes Bazaar/Player Trading from MISSING to PARTIAL without pretending that the offline client is a secure market backend. The client receives a monotonic read-only listing snapshot, can retain local search/filter preferences, and renders a dedicated Command Deck Bazaar surface. Live listing creation/cancellation/purchase, escrow, gold/item transfer, fee calculation and anti-abuse decisions remain server-authoritative and idempotent.

Canonical V3.8 market contract preserved: primarily Gold; configurable 12/24/48-hour examples; non-refundable listing fee; sale tax; filters by item type/tier/family/price/region/tags; no uncontrolled direct Gold transfer as the standard path; binding is driven by ItemDefinition. Tradeable, Bind on Equip, Account Bound, Ship Bound, Guild Bound and Event Bound remain distinct states.

V3.8's 2% listing fee / 5% sale tax are represented only as non-final starting hypotheses. They are not hard-coded transaction authority and must remain live-configurable. Anti-manipulation contract covers RMT/gold transfer, price fixing, bot farming, alt accounts, duplication, cancel abuse, event hoarding and insider LiveOps with server telemetry/audit boundaries.
