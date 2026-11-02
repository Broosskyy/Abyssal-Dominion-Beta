# Abyssal Dominion — M239 Production Report

M239 is a V3.8 master-convergence/runtime-hardening milestone rather than another Season feature milestone. It adds a source-backed production-readiness matrix, explicit production-boundary contract and a read-only readiness catalog.

A concrete canonical-combat mismatch was fixed: enemy AI previously waited for broadside alignment before firing. V3.8 defines facing/broadside as irrelevant to the canonical attack contract. M239 now permits valid in-range enemy attacks regardless of facing while retaining broadside-looking steering/presentation. No damage, range or reload values were changed.

Online gateway stubs now expose explicit unavailable/foundation capability reports. This prevents future UI/dev layers from accidentally treating Auth/Repository/Transport contracts as production services. Native Godot/device visual QA is still pending.
