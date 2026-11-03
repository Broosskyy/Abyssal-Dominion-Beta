extends SceneTree
const MODEL=preload("res://updater/update_model.gd")
const CONTROLLER=preload("res://updater/update_controller.gd")
var failures: Array[String]=[]
var count=0
class FakeNative extends RefCounted:
	var queued=0
	var cleared=0
	var status={"status":"running","version":305702,"received":500000,"total":1000000}
	func enqueueBackgroundApk(_url: String,_version: int,_digest: String,_length: int) -> String:queued+=1;return "queued"
	func queryBackgroundApk() -> String:return JSON.stringify(status)
	func discardBackgroundApk() -> String:cleared+=1;return "cleared"
	func installValidatedApk(_path: String,_version: int) -> String:return "permission_required"

func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)

func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	var bytes=PackedByteArray();bytes.resize(1000000);bytes.fill(41)
	var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	var next_code=MODEL.VERSION_CODE+1
	var spec={"version_code":next_code,"package":MODEL.PACKAGE,"certificate_sha256":MODEL.CERT,"bytes":1000000,"sha256":hash.finish().hex_encode(),"url":MODEL.release_url(next_code)}
	check(MODEL.valid_spec(spec),"accept correctly pinned future release")
	check(MODEL.manifest({"schema":1,"channel":"test","latest":spec}).status=="available","newer version offered")
	check(MODEL.manifest({"schema":1,"channel":"test","latest":spec},next_code).status=="current","same version does not download again")
	check(MODEL.manifest({"schema":1,"channel":"test","latest":spec},next_code+1).status=="current","downgrade not offered")
	for patch in [{"package":"wrong.app"},{"certificate_sha256":"f".repeat(64)},{"url":"http://evil.test/app.apk"},{"url":MODEL.release_url(next_code+1)},{"version_code":305702.5},{"version_code":"305702"},{"version_code":true},{"bytes":999999},{"bytes":350000001},{"bytes":1000000.5},{"sha256":"F".repeat(64)},{"sha256":"0".repeat(63)}]:
		var bad=spec.duplicate(true);bad.merge(patch,true)
		check(not MODEL.valid_spec(bad),"reject altered update metadata "+str(patch.keys()))
	check(MODEL.manifest({"schema":2,"channel":"test","latest":spec}).status=="invalid","unknown schema rejected")
	check(MODEL.manifest({"schema":1,"channel":"global","latest":spec}).status=="invalid","wrong release channel rejected")
	check(MODEL.manifest([]).status=="invalid","non-object manifest rejected")
	var path="user://updater_fixture.apk"
	var file=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
	check(MODEL.verify_file(spec,path),"complete file accepted only with matching checksum")
	bytes[0]=42;file=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
	check(not MODEL.verify_file(spec,path),"same-size modified APK rejected")
	file=FileAccess.open(path,FileAccess.WRITE);file.store_string("partial");file.close()
	check(not MODEL.verify_file(spec,path),"partial download rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var native=FakeNative.new();native.status.version=next_code
	var controller=CONTROLLER.new();controller.native=native;root.add_child(controller)
	controller._manifest_complete(HTTPRequest.RESULT_SUCCESS,503,PackedStringArray(),PackedByteArray())
	check(controller.state=="offline" and native.queued==0,"server failure leaves game playable without starting download")
	controller._manifest_complete(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),"broken json".to_utf8_buffer())
	check(controller.state=="error" and native.queued==0,"broken manifest never reaches native download")
	controller.auto_download=false
	controller._manifest_complete(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"schema":1,"channel":"test","latest":spec}).to_utf8_buffer())
	check(controller.state=="available" and native.queued==0,"validated available release can be reviewed before download")
	controller.download()
	check(native.queued==1 and controller.state=="downloading","valid update enqueued through native downloader")
	controller.download();check(native.queued==1,"foreground repeated action does not enqueue duplicate")
	controller._apply_native_state(native.status)
	check(is_equal_approx(controller.progress,0.5),"native received bytes drive progress")
	controller.queue_free();await process_frame
	check(native.cleared==0,"leaving launcher keeps system download alive")
	var resumed=CONTROLLER.new();resumed.native=native;root.add_child(resumed)
	check(resumed._resume() and resumed.state=="downloading" and native.queued==1,"new controller resumes persisted request without duplicate")
	resumed._apply_native_state({"status":"paused","version":next_code,"received":500000})
	check(resumed.state=="paused","network pause remains resumable")
	resumed._apply_native_state(native.status);check(resumed.state=="downloading","native running status resumes progress")
	resumed.verified_path="user://fixture.apk";resumed.state="ready";resumed.install()
	check(resumed.state=="permission","installer permission stays actionable")
	resumed.queue_free();await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CONTROLLER.PENDING))
	var scene=load("res://updater/launcher.tscn").instantiate();scene.autostart=false;root.add_child(scene)
	await process_frame
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions;await process_frame;scene._layout();await process_frame
		for control: Control in [scene.action,scene.play]:
			var rect=control.get_global_rect()
			check(rect.size.x>100 and rect.size.y>=44 and rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"updater action visible at "+str(dimensions))
		check(not scene.action.get_global_rect().intersects(scene.play.get_global_rect()),"updater actions do not overlap at "+str(dimensions))
	scene.queue_free();await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures,"native_download_simulation":true,"physical_android_test":false}))
	quit(0 if failures.is_empty() else 1)
