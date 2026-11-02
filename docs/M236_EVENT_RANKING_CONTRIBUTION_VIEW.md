# M236 — Event Ranking & Contribution View

M236 turns the M235 server-replica contract into a dedicated, scrollable Command Deck presentation. The Events page now shows personal contribution, group contribution, supported contribution breakdown, personal/group rank, next server-provided threshold, qualification state and published reward summary. Optional top-10 rows are rendered only when supplied by the authoritative snapshot; no fake players or ranks are generated.

The Rankings page exposes a compact active-event summary and routes to Events for detail. Normal gameplay HUD remains limited to short transition feedback. The client never computes authoritative rank, marks itself qualified, claims rewards or changes event phases. Mobile/Web/Desktop share the same information architecture; only responsive sizing, spacing and columns differ through the existing Command Deck policy.
