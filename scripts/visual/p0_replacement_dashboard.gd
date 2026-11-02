class_name P0ReplacementDashboard
extends RefCounted
const PATH:="res://data/m105_p0_replacement_dashboard.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
static func summary_line()->String:
	var s:Dictionary=data().get("summary",{})
	return "P0 · %d/13 Source · %d/13 Final · %d Fallback · Native Mobile %d/13"%[
		int(s.get("source_ready",0)),int(s.get("final",0)),int(s.get("fallback_ready",0)),int(s.get("native_mobile_pass",0))]
static func asset_line(id:String)->String:
	for row in data().get("assets",[]):
		if str(row.get("id",""))==id:return "#%02d · %s · %s · Mobile %s"%[int(row.order),id,str(row.state),str(row.mobile_qa)]
	return id+" · UNKNOWN"


static func checklist_line(id:String)->String:
	var checklist:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m106_p0_final_art_checklist.json"))
	if not checklist is Dictionary:return "Checklist unavailable"
	for row in checklist.get("assets",[]):
		if str(row.get("id",""))==id:
			return "FINAL ART · %s · %d Checks · Native %s"%[str(row.get("state","")),row.get("checklist",[]).size(),str(row.get("native_status","PENDING"))]
	return "FINAL ART · unknown"
