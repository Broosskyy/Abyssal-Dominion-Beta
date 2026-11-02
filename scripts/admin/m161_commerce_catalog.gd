class_name M161CommerceCatalog
extends Node

const PATH := "res://data/m161_commerce_catalog.json"
var data: Dictionary = {}

func _ready() -> void:
	add_to_group("commerce_catalog")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	data = parsed if parsed is Dictionary else {}

func shops() -> Array:
	return data.get("shops", [])

func offers() -> Array:
	return data.get("offers", [])

func shop(shop_id: String) -> Dictionary:
	for row in shops():
		if row is Dictionary and str(row.get("id", "")) == shop_id:
			return (row as Dictionary).duplicate(true)
	return {}

func offer(offer_id: String) -> Dictionary:
	for row in offers():
		if row is Dictionary and str(row.get("id", "")) == offer_id:
			return (row as Dictionary).duplicate(true)
	return {}

func offers_for_shop(shop_id: String) -> Array:
	var definition := shop(shop_id)
	var ids: Array = definition.get("offer_ids", [])
	var out: Array = []
	for id in ids:
		var row := offer(str(id))
		if not row.is_empty(): out.append(row)
	return out

func summary() -> Dictionary:
	var real_money := 0
	for row in offers():
		if row is Dictionary and str(row.get("kind", "")) == "real_money": real_money += 1
	return {"shops":shops().size(),"offers":offers().size(),"real_money":real_money,"authority":str(data.get("authority", ""))}

func validate_offer(row: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if str(row.get("id", "")).is_empty(): errors.append("offer_id_required")
	if str(row.get("label", "")).is_empty(): errors.append("offer_label_required")
	if str(row.get("kind", "")) == "real_money":
		for e in MonetizationAdminContract.validate_public_product(row): errors.append(e)
	elif int(row.get("amount", 0)) <= 0 or float(row.get("price", -1)) < 0:
		errors.append("invalid_soft_currency_offer")
	return errors
