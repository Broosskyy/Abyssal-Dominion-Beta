class_name M247BazaarTradingCatalog
extends RefCounted

static func overview_card(runtime: M247BazaarTradingRuntime) -> Dictionary:
	if runtime == null: return {"title":"SPIELERBASAR","state":"RUNTIME FEHLT","detail":"Markt-Replica nicht verfügbar.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER":
		return {"title":"SPIELERBASAR","state":"SERVERDATEN AUSSTEHEND","detail":"Keine lokalen Listings, Preise, Käufe oder Verkäufe werden erfunden. Primäre Basarwährung ist Gold.","tone":"info"}
	var summary = snap.get("summary", {})
	if not summary is Dictionary: summary = {}
	return {"title":"SPIELERBASAR","state":"%d ANGEBOTE · %d EIGENE" % [int(summary.get("listing_count", runtime.listing_rows().size())),int(summary.get("my_listing_count", runtime.my_listing_rows().size()))],"detail":"Serverbestätigte Listings. Kauf, Verkauf, Escrow, Gebühren und Transfers bleiben atomare Servertransaktionen.","tone":"ready"}

static func listing_card(row: Dictionary) -> Dictionary:
	var quantity := maxi(1, int(row.get("quantity", 1)))
	var unit_price := int(row.get("unit_price", 0))
	var total_price := int(row.get("total_price", quantity * unit_price))
	var detail := "%d × %d Gold · Gesamt %d Gold" % [quantity,unit_price,total_price]
	var family := str(row.get("family", "")); var region := str(row.get("region", ""))
	if not family.is_empty(): detail += " · " + family
	if not region.is_empty(): detail += " · " + region
	return {"title":str(row.get("item_name", row.get("item_id", "Listing"))),"state":"T%d · %s" % [int(row.get("tier",1)),str(row.get("state","active")).to_upper()],"detail":detail,"tone":"ready"}

static func contract_card(runtime: M247BazaarTradingRuntime) -> Dictionary:
	if runtime == null: return {"title":"BASAR-VERTRAG","state":"NICHT VERFÜGBAR","detail":"","tone":"locked"}
	var c := runtime.contract(); var m: Dictionary = c.get("master_contract", {}); var b: Dictionary = c.get("balance", {})
	return {"title":"BASAR-VERTRAG","state":"GOLD · LISTING + SALE TAX","detail":"Laufzeiten %s h · Filter nach Typ/Tier/Familie/Preis/Region/Tags. Gebührenhypothese %.0f%% Listing / %.0f%% Sale Tax ist NICHT final und serverseitig konfigurierbar." % ["/".join(PackedStringArray(["12","24","48"])),float(b.get("listing_fee_percent_start_hypothesis",2.0)),float(b.get("sale_tax_percent_start_hypothesis",5.0))],"tone":"info"}

static func authority_card(runtime: M247BazaarTradingRuntime) -> Dictionary:
	return {"title":"ESCROW & TRANSAKTIONEN","state":"SERVER REQUIRED","detail":"Client erstellt/kauft/storniert keine Live-Listings, verschiebt kein Escrow und überträgt weder Gold noch Items. Keine freien direkten Goldtransfers als Standard.","tone":"locked"}
