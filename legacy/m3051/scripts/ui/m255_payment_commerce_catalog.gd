class_name M255PaymentCommerceCatalog
extends RefCounted

static func overview(runtime: M255PaymentCommerceRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER":
		return {"title":"PAYMENT & ENTITLEMENTS","state":"SERVER ERFORDERLICH","detail":"Keine Fake-Käufe, Storepreise, Receipts oder Entitlements. Der Client zeigt nur bestätigte Provider-/Serverdaten.","tone":"locked"}
	var snap := runtime.snapshot()
	return {"title":"PAYMENT & ENTITLEMENTS","state":"SERVERDATEN","detail":"%d Angebote · %d Käufe · %d Entitlements" % [runtime.offer_rows().size(),runtime.purchase_rows().size(),runtime.entitlement_rows().size()],"tone":"info"}

static func offer_card(row: Dictionary) -> Dictionary:
	var label := str(row.get("label", row.get("product_id", "Shopangebot")))
	var price := str(row.get("display_price", "Preis vom Store-Provider"))
	return {"title":label.to_upper(),"state":str(row.get("state","AVAILABLE")).to_upper(),"detail":"%s · Besitz erst nach serverseitiger Receipt-Verifikation." % price,"tone":"ready"}

static func purchase_card(row: Dictionary) -> Dictionary:
	var state := str(row.get("status","pending")).to_upper()
	return {"title":"KAUF · %s" % str(row.get("product_id","PRODUKT")),"state":state,"detail":"Purchase-ID %s · serverseitig nachvollziehbar" % str(row.get("purchase_id","—")),"tone":"info" if state in ["ACTIVE","CONFIRMED"] else "locked"}

static func entitlement_card(row: Dictionary) -> Dictionary:
	var state := str(row.get("status","active")).to_upper()
	return {"title":"ENTITLEMENT","state":state,"detail":str(row.get("label",row.get("entitlement_id","Serverbestätigter Besitz"))),"tone":"ready" if state == "ACTIVE" else "info"}

static func authority_card() -> Dictionary:
	return {"title":"COMMERCE-AUTORITÄT","state":"SERVER ONLY","detail":"Receipt-Prüfung, PurchaseTransaction, Entitlement, Premium-Wallet, Refund, Chargeback und Revocation bleiben serverautoritativ und replay-geschützt.","tone":"locked"}
