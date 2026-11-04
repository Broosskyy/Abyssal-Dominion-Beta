class_name M266EconomyInventoryTransactionCatalog
extends RefCounted
static func overview(runtime: M266EconomyInventoryTransactionRuntime) -> Dictionary:
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"title":"Economy · Inventory Transactions","state":"BACKEND ERFORDERLICH","detail":"LOCAL zeigt keine echten Wallet-/Inventory-Commits und erzeugt keine Server-Receipts."}
	return {"title":"Economy · Inventory Transactions","state":"SERVER VERIFIZIERT","detail":"Environment %s · Transaktionsrevision %d" % [str(snap.get("environment","?")), int(snap.get("revision",-1))]}
static func wallet(runtime: M266EconomyInventoryTransactionRuntime) -> Dictionary:
	var row := runtime.wallet_state()
	if row.is_empty(): return {"title":"Wallet · Ledger","state":"SERVER ONLY","detail":"Gold, Premium-/Eventwährungen und andere Werte werden nur aus autoritativen Ledgerständen dargestellt."}
	return {"title":"Wallet · Ledger","state":"SERVER SNAPSHOT","detail":"Walletwerte stammen aus der bestätigten Economy-Wahrheit; Clientwerte sind kein Commitbeleg."}
static func inventory(runtime: M266EconomyInventoryTransactionRuntime) -> Dictionary:
	var rows := runtime.inventory_rows()
	if rows.is_empty(): return {"title":"Inventory · Ownership Mutation","state":"FAIL CLOSED","detail":"Loot, Shop, Crafting, Salvage und Equipment-Mutationen benötigen atomare Servertransaktionen."}
	return {"title":"Inventory · Ownership Mutation","state":"%d INSTANZEN" % rows.size(),"detail":"Nur serverbestätigte Instanzänderungen gelten als dauerhaft."}
static func transactions(runtime: M266EconomyInventoryTransactionRuntime) -> Dictionary:
	var rows := runtime.recent_transactions(); var locks := runtime.lock_rows()
	if rows.is_empty(): return {"title":"Atomic Transactions","state":"IDEMPOTENT · SERVER ONLY","detail":"Request-ID, Transaction-ID, Idempotency-Key, Revision Guard, Locks und Receipt schützen vor Double-Spend/Dupe."}
	return {"title":"Atomic Transactions","state":"%d RECENT · %d LOCKS" % [rows.size(), locks.size()],"detail":"Commit/Abort/Conflict/Receipt werden ausschließlich serverseitig bestätigt."}
static func authority() -> Dictionary:
	return {"title":"Economy Authority","state":"SERVER ONLY","detail":"Client kann Wallet/Inventory, Loot, Shop, Crafting, Salvage, Bazaar oder Receipts nicht selbst settlen und TEST-Wert nicht nach GLOBAL übertragen."}
