class_name M258BackupDisasterRecoveryCatalog
extends RefCounted

static func overview(runtime: M258BackupDisasterRecoveryRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "OPERATIONS":
		return {"title":"BACKUP & RECOVERY","state":"OPS NICHT VERBUNDEN","detail":"Keine Fake-Backups oder Fake-Restore-Bereitschaft. Produktionsstatus muss aus verifizierten Operations-Daten kommen.","tone":"locked"}
	return {"title":"BACKUP & RECOVERY","state":"SERVERBESTÄTIGT","detail":"Backup-Health, Restore-Readiness und DR-Status sind read-only veröffentlicht.","tone":"info"}

static func backup(runtime: M258BackupDisasterRecoveryRuntime) -> Dictionary:
	var count := runtime.backup_health_rows().size() if runtime != null else 0
	return {"title":"KRITISCHE DATENBACKUPS","state":"%d STATUSDATEN" % count if count > 0 else "KEINE LIVE-DATEN","detail":"Account, Ownership, Economy, Guild, Bazaar, Payment/Entitlements und Config: automatisiert nach Kritikalität, verschlüsselt und zugriffsbeschränkt.","tone":"info"}

static func restore(runtime: M258BackupDisasterRecoveryRuntime) -> Dictionary:
	var row := runtime.restore_readiness() if runtime != null else {}
	return {"title":"PITR & RESTORE TESTS","state":str(row.get("state","NICHT VERIFIZIERT")).to_upper(),"detail":"Ein vorhandenes Backup beweist keine Wiederherstellbarkeit. Restore-Tests laufen isoliert; RPO/RTO werden je Datenklasse dokumentiert.","tone":"locked" if row.is_empty() else "info"}

static func disaster(runtime: M258BackupDisasterRecoveryRuntime) -> Dictionary:
	var row := runtime.disaster_recovery() if runtime != null else {}
	return {"title":"DISASTER RECOVERY","state":str(row.get("state","DRILL AUSSTEHEND")).to_upper(),"detail":"Priorität: Auth → Account → Ownership/Economy → World → Payment → Website/Status → Support. Wiederanlauf bleibt Operations-Aufgabe.","tone":"locked" if row.is_empty() else "info"}

static func authority() -> Dictionary:
	return {"title":"RECOVERY-AUTORITÄT","state":"OPS / SERVER ONLY","detail":"Client darf weder Restore/PITR ausführen noch RPO/RTO ändern, Recovery als erfolgreich markieren oder Account-/Economy-Werte kompensieren.","tone":"locked"}
