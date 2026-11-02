class_name MonetizationAdminContract
extends RefCounted
static func editable_fields()->PackedStringArray:
	return PackedStringArray(["display_name","description","display_price","sale_window","bundle_contents","purchase_limit","provider_product_id","entitlement_id"])
static func client_may_grant_entitlement()->bool:return false
static func requires_server_receipt_validation()->bool:return true
static func validate_public_product(row:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray()
	if str(row.get("provider_product_id","")).is_empty():errors.append("provider_product_id_required")
	if str(row.get("entitlement_id","")).is_empty():errors.append("entitlement_id_required")
	if row.has("secret") or row.has("api_key"):errors.append("secrets_forbidden_in_client_config")
	return errors
