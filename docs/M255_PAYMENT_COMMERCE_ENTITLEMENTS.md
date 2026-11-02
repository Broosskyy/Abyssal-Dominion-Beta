# M255 — Payment / Commerce / Entitlements

M255 implements the V3.8 client-side authority boundary for paid commerce. The existing global shop remains the user-facing destination; M255 does not create a second shop.

The client may present catalog rows and create a purchase-intent envelope. Real price resolution comes from a store provider/server catalog. Receipt validation, idempotent PurchaseTransaction creation, Entitlement grants, premium-wallet mutation, refund/chargeback/revocation handling and GLOBAL/TEST isolation remain server-owned.

No final prices, booster values or payment-power values were invented. No permanent commerce indicator is added to the world HUD. Responsive Command Deck cards reuse the existing information architecture and presentation-only transitions.
