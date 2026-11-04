# M263 — Online Alpha End-to-End Server Contract

V3.8 Online Alpha prioritizes technical correctness: account, persistent ownership, movement, combat, basic PvE/PvP interaction, reconnect, server stability and data integrity. M263 connects those existing client boundaries into one fail-closed contract.

LOCAL remains a prototype. It may prepare client intents, but it never reports a successful backend transaction. Auth/account/session/world authority, movement/combat resolution, persistence, resume verdict and clean-leave acknowledgement remain server-owned. TEST and GLOBAL evidence stay isolated.

No final timeout, tick-rate, retry, latency or rejoin-window values are invented. Native/backend verification remains required.
