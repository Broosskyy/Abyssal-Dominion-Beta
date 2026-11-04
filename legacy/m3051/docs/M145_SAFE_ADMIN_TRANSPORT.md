# M145 Safe Admin Transport

M145 adds the first executable transport boundary between the M144 shared admin envelope and a future Abyssal Dominion service. It deliberately does not create production authority.

## Runtime flow

The admin gateway creates a request ID before emitting an envelope. Write methods are sanitized, deduplicated and stored in a bounded local queue. When a profile is enabled with an `https://` base URL, the adapter sends the envelope with the same request ID as `Idempotency-Key`. A response is accepted only after successful HTTPS completion, a 2xx code, required response fields and `server_verified=true`.

Snapshot reads are ephemeral. An offline or failed read is cancelled instead of entering the write queue. A returned snapshot must match `abyssal-content-snapshot-v1` before the snapshot service activates it.

## Security boundary

- No credential, token, password, cookie, secret or MFA code is persisted.
- TEST and STAGING ship disabled and without URLs.
- GLOBAL is always rejected by the client adapter in M145, even if configuration is edited.
- Server RBAC, MFA, approval, revision guards, audit and database transactions remain mandatory.
- Client labels, roles and displayed buttons are never treated as authorization.

## Cross-platform rule

Windows, macOS, Linux, Android and iOS use the same HTTPS JSON envelope. Web preview uses a future same-origin proxy. All platforms consume the same content IDs and AssetSlots; only quality variants differ.
