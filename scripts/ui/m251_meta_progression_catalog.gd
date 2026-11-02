class_name M251MetaProgressionCatalog
extends RefCounted

static func overview(runtime: M251MetaProgressionRuntime) -> Dictionary:
	var source := "LOCAL_PREVIEW" if runtime == null else str(runtime.snapshot().get("source", "LOCAL_PREVIEW"))
	return {"title":"BEGLEITER · ARTEFAKTE · AFK", "state":"SERVER VERBUNDEN" if source == "SERVER" else "SERVER ERFORDERLICH", "detail":"Langfristige Meta-Progression mit klarer Ownership-/Claim-Grenze. Lokale Definitionen bleiben Vorschau, nicht Besitz.", "tone":"active" if source == "SERVER" else "info"}

static func companion(runtime: M251MetaProgressionRuntime) -> Dictionary:
	if runtime != null and str(runtime.snapshot().get("source", "")) == "SERVER":
		var active := runtime.active_companion()
		var name := str(active.get("name", active.get("id", "Kein aktiver Begleiter")))
		var role := str(active.get("role", ""))
		var level := str(active.get("level", "?"))
		return {"title":"BEGLEITER", "state":name.to_upper(), "detail":"Rolle %s · Level %s · Sammlung %d" % [role, level, runtime.companion_rows().size()], "tone":"active"}
	return {"title":"BEGLEITER", "state":"DEFINITIONEN BEREIT", "detail":"Combat · Defense · Support · Hunter · Loot/Salvage · Navigation · Exploration · Utility. Auf See nur spielrelevante Kurzinfo.", "tone":"info"}

static func artifacts(runtime: M251MetaProgressionRuntime) -> Dictionary:
	if runtime != null and str(runtime.snapshot().get("source", "")) == "SERVER":
		return {"title":"ARTEFAKTE", "state":"%d IM BESITZ" % runtime.artifact_rows().size(), "detail":"Aktive Slots %d · Mastery/Resonanz/Sets werden ausschließlich aus Serverzustand dargestellt." % runtime.artifact_loadout_rows().size(), "tone":"active"}
	return {"title":"ARTEFAKTE", "state":"BUILD-SPEZIALISIERUNG", "detail":"War · Defense · Navigation · Hunter · Fortune · Support · Exploration · Guild · Event · Abyssal. Wenige aktive Slots statt Itemwand.", "tone":"info"}

static func afk(runtime: M251MetaProgressionRuntime) -> Dictionary:
	if runtime != null and str(runtime.snapshot().get("source", "")) == "SERVER":
		var state := runtime.afk_state()
		var claim_state := str(state.get("claim_state", "NICHT VERFÜGBAR"))
		var profile := str(state.get("profile_name", state.get("profile_id", "Captain Expedition")))
		return {"title":"AFK / HAFENOPERATION", "state":claim_state.to_upper(), "detail":"%s · Offlinezeit und Rewardauflösung stammen aus vertrauenswürdiger Serverzeit; aktiver Claim erforderlich." % profile, "tone":"active" if claim_state.to_lower() in ["ready","claimable"] else "info"}
	return {"title":"AFK / HAFENOPERATION", "state":"KEINE LOKALEN REWARDS", "detail":"Kein Hintergrundkampf. Kein Ranked, Guild War, Admiral, World Boss, Eventranking oder seltener Endgame-Drop. Exakte Caps/Raten bleiben Balancingdaten.", "tone":"locked"}

static func authority(runtime: M251MetaProgressionRuntime) -> Dictionary:
	return {"title":"ONLINE-AUTORITÄT", "state":"SERVER", "detail":"Ownership, Level/Mastery/Traits, Artefaktprogression, Offlinezeit, Rewardauflösung, Claims und Transaction Receipts werden clientseitig niemals erzeugt.", "tone":"locked"}
