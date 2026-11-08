extends SceneTree
const TRANSFER=preload("res://updater/direct_transfer.gd")
const DATA=preload("res://updater/data_controller.gd")
const APK=preload("res://updater/update_controller.gd")
var failures: Array[String]=[]
var checks:=0
class FakeNative extends RefCounted:
	var cleared:=0
	func discardBackgroundPack() -> String:cleared+=1;return "cleared"
	func discardBackgroundApk() -> String:cleared+=1;return "cleared"
class FakeTransfer extends Node:
	signal changed
	signal finished(path: String)
	signal failed(reason: String)
	var active:=false
	var progress:=0.0
	var attempt:=1
	var calls:=0
	var path: String=""
	func start(_url: String,destination: String,_bytes: int) -> bool:calls+=1;path=destination;active=true;return true
	func cleanup() -> void:pass
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for script in [DATA,APK]:
		var native=FakeNative.new();var controller=script.new();controller.native=native;root.add_child(controller)
		controller.set_process(false)
		controller.direct.queue_free()
		var fake=FakeTransfer.new();controller.add_child(fake);controller.direct=fake
		fake.failed.connect(controller._direct_failed)
		controller.spec={"revision":900,"version_code":900,"url":TRANSFER.ROOT+"data-900/ABYSSAL_DATA_900.zip","bytes":1000000}
		var status: Dictionary={"version":900,"status":"failed","reason":1005}
		if script==DATA:controller.apply_status(status)
		else:controller._apply_native_state(status)
		check(controller.foreground_transfer and controller.state=="downloading" and fake.calls==1,"native failure automatically starts independent transfer")
		check(native.cleared==1,"terminal native job is discarded before recovery")
		controller._start_fallback("repeat")
		check(fake.calls==1,"repeated failure does not duplicate recovery transfer")
		fake.failed.emit("HTTP 503")
		check(controller.state=="error" and not controller.foreground_transfer and "503" in controller.message,"terminal recovery failure remains explicit and retryable")
		controller.queue_free();await process_frame
	check("1005" in TRANSFER.native_reason({"reason":1005,"status":"failed"}),"Android reason is retained for diagnosis")
	var launcher=load("res://updater/launcher.tscn").instantiate();launcher.autostart=false;root.add_child(launcher);await process_frame
	launcher.content_started=true;launcher.content.foreground_transfer=true;launcher.content.state="downloading";launcher._refresh()
	check(launcher.play.disabled and "OFFEN LASSEN" in launcher.play.text,"foreground recovery cannot be accidentally canceled by entering the game")
	launcher.content.foreground_transfer=false;launcher.content.state="error";launcher._refresh()
	check(not launcher.play.disabled,"saved game stays accessible after a failed download")
	launcher.queue_free();await process_frame
	# Exercise the actual threaded HTTP-to-file implementation against a local server.
	var server=TCPServer.new()
	var error: int=server.listen(18973,"127.0.0.1")
	check(error==OK,"local transfer test server starts")
	if error!=OK:finish();return
	var transfer=TRANSFER.new();root.add_child(transfer);transfer.allow_local_test=true
	check(not transfer.start("http://other.invalid/file","user://direct_test.bin",1000000),"non-release URLs are refused outside controlled loopback test")
	check(not transfer.start(TRANSFER.ROOT+"file","user://../captain.json",1000000),"transfer destinations cannot overwrite a captain save")
	var body=PackedByteArray();body.resize(1000000);body.fill(61)
	var outcome: Array=[]
	transfer.finished.connect(func(path: String):outcome.append(path))
	transfer.failed.connect(func(reason: String):outcome.append("FAIL "+reason))
	check(transfer.start("http://127.0.0.1:18973/retry","user://direct_test.bin",body.size()),"actual direct transfer starts")
	var served:=0
	var peers: Array[StreamPeerTCP]=[]
	for _frame in 100:
		if server.is_connection_available():peers.append(server.take_connection())
		for peer: StreamPeerTCP in peers.duplicate():
			peer.poll()
			if peer.get_available_bytes()==0:continue
			peer.get_data(peer.get_available_bytes());served+=1
			var response: PackedByteArray=("HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n").to_utf8_buffer() if served==1 else ("HTTP/1.1 200 OK\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % body.size()).to_utf8_buffer()
			peer.put_data(response)
			if served>1:peer.put_data(body)
			peer.disconnect_from_host();peers.erase(peer)
		if transfer.retry_wait>0:transfer.retry_wait=.001
		if not outcome.is_empty():break
		await process_frame
	check(served==2 and outcome==["user://direct_test.bin"],"HTTP 503 retries and then completes a real file download")
	check(FileAccess.get_file_as_bytes("user://direct_test.bin")==body,"streamed recovery file preserves every byte")
	var verifier=DATA.new();verifier.native=FakeNative.new();root.add_child(verifier);verifier.set_process(false)
	var revision_before: int=verifier.boot.active_revision
	verifier.spec={"revision":900,"bytes":1000000};verifier.foreground_transfer=true;verifier._direct_complete("user://direct_test.bin")
	for _i in 10:
		await process_frame;verifier._process(.01)
		if verifier.state=="error":break
	check(verifier.state=="error" and verifier.boot.active_revision==revision_before,"a completed direct download cannot bypass signed content verification")
	verifier.queue_free();transfer.cleanup();transfer.queue_free();server.stop();await process_frame
	finish()
func finish() -> void:
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
