# Abyssal Dominion — M237 Production Report

M237 adds server-authoritative event-history continuity on top of the M235 contribution replica and M236 ranking UI. Completed events can now be represented with historical contribution, personal/group placement, qualified tier and settlement state. Server-confirmed reward receipts have a dedicated read-only representation.

The client does not create history, compute historical ranks, declare settlement, grant rewards or generate receipt ids. Snapshot revisions are monotonic and a missing server snapshot produces an explicit empty state rather than fake data.

Gameplay balance, navigation, collision, event reward values, M213/M214 camera, circular gameplay minimap and rectangular full sea chart are unchanged.
