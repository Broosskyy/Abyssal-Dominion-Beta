class_name M267AuthoritativeWorldTransportCatalog
extends RefCounted

static func overview(runtime: M267AuthoritativeWorldTransportRuntime) -> Dictionary:
	if runtime == null: return {"title":"World Transport","state":"FOUNDATION","detail":"Runtime fehlt; Live-Weltzustand wird nicht simuliert."}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"title":"World Transport","state":"BACKEND ERFORDERLICH","detail":"LOCAL besitzt keine autoritative World-Snapshot-Wahrheit."}
	return {"title":"World Transport","state":"SERVER VERIFIZIERT","detail":"%s · Instanz %s · Baseline %s" % [str(snap.get("environment","?")),str(snap.get("instance_id","?")),str(snap.get("baseline_id","?"))]}

static func sequencing(runtime: M267AuthoritativeWorldTransportRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"Tick · Revision · Sequence","state":"SERVER ONLY","detail":"Tick, Snapshot-Revision und Sequenz werden nicht lokal fortgeschrieben."}
	var s:=runtime.snapshot(); return {"title":"Tick · Revision · Sequence","state":"TICK %d · REV %d · SEQ %d" % [int(s.get("server_tick",-1)),int(s.get("snapshot_revision",-1)),int(s.get("sequence",-1))],"detail":"Stale/duplicate/out-of-order Pakete können keinen neueren Zustand überschreiben."}

static func entities(runtime: M267AuthoritativeWorldTransportRuntime) -> Dictionary:
	var n:=runtime.entity_rows().size() if runtime!=null else 0
	return {"title":"Network Entities","state":"%d REPLIKATE"%n if n>0 else "SERVER SNAPSHOT ERFORDERLICH","detail":"Stabile Network-IDs + Spawn-Generation schützen Entity-Lebenszyklen; Client rendert nur Replikate."}

static func resync_transfer(runtime: M267AuthoritativeWorldTransportRuntime) -> Dictionary:
	if runtime==null: return {"title":"Join · Transfer · Resync","state":"FOUNDATION","detail":"Join/Transfer/Resync benötigen Serververdict und neue Baseline."}
	var s:=runtime.snapshot(); var pending:=bool(s.get("resync_pending",false))
	return {"title":"Join · Transfer · Resync","state":"RESYNC ERFORDERLICH" if pending else "SERVER CONTROLLED","detail":"Baseline bei Join/Rejoin/Transfer; Sequence-Gaps/Baseline-Mismatch erzwingen Resync. %s" % str(s.get("resync_reason",""))}

static func authority() -> Dictionary:
	return {"title":"World Authority","state":"SERVER ONLY","detail":"Client darf Snapshots/Deltas, Network-IDs, Ticks, Spawn/Despawn oder Transfer-Verdicts nicht autoritativ erzeugen. TEST und GLOBAL bleiben getrennt."}
