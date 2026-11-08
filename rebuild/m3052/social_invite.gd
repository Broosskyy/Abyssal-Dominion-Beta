extends RefCounted
## Friend-invite presentation is local-only. Never award referral currency,
## create fake friendships, or claim that a code has been redeemed online.
const BETA_RELEASES := "https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases"

static func invite_code(captain_id: String) -> String:
	var raw: String=captain_id.strip_edges().to_upper()
	if raw.length()!=12 or not raw.is_valid_hex_number():return ""
	return "ADM-"+raw

static func invite_text(captain_name: String,captain_id: String) -> String:
	var code: String=invite_code(captain_id)
	if code.is_empty():return ""
	var display_name: String=captain_name.strip_edges().left(24)
	if display_name.is_empty():display_name="Ein Kapitän"
	return "%s lädt dich zu Abyssal Dominion ein!\\nMein Beta-Einladungscode: %s\\nSpielversion & Releases: %s\\nHinweis: Freundesliste und Einladungsbelohnungen werden erst mit Online-Konten freigeschaltet." % [display_name,code,BETA_RELEASES]

static func is_invite_code(value: String) -> bool:
	var code: String=value.strip_edges().to_upper()
	return code.begins_with("ADM-") and invite_code(code.trim_prefix("ADM-"))==code
