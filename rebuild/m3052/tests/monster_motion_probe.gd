extends RefCounted
## GPU test: deforming limbs must alter rendered pixels; quiet mode must not.
class MonsterCanvas extends Node2D:
	var key: String="kraken"
	var time: float=0.0
	var moving: bool=true
	var texture: Texture2D
	func _draw() -> void:
		var dims: Vector2=texture.get_size()*210.0/maxf(texture.get_width(),texture.get_height())
		draw_mesh(preload("res://monster_motion.gd").frame(key,time,100,moving),texture,Transform2D(0.0,dims,0.0,Vector2(128,128)))

static func run(tree: SceneTree) -> Dictionary:
	var failures: Array[String]=[]
	var counts: Array=[]
	var viewport=SubViewport.new();viewport.size=Vector2i(256,256)
	viewport.world_2d=World2D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var canvas=MonsterCanvas.new();viewport.add_child(canvas)
	for key: String in ["kraken","serpent","crab"]:
		canvas.key=key;canvas.texture=load("res://assets/expansion/%s.webp" % key)
		for moving in [false,true]:
			canvas.moving=moving
			var images: Array[PackedByteArray]=[]
			for time in [0.0,.5]:
				canvas.time=time;canvas.queue_redraw()
				for frame in 3:await tree.process_frame
				await RenderingServer.frame_post_draw
				images.append(viewport.get_texture().get_image().get_data())
			var changed: int=0
			if images[0].is_empty() or images[0].size()!=images[1].size():failures.append("missing monster GPU image")
			else:
				for index in range(0,images[0].size(),16):
					if images[0][index]!=images[1][index] or images[0][index+1]!=images[1][index+1] or images[0][index+2]!=images[1][index+2]:changed+=1
			if moving and changed<60:failures.append(key+" limbs did not animate")
			if not moving and changed!=0:failures.append(key+" quiet mode still animates")
			counts.append({"monster":key,"motion":moving,"changed_samples":changed})
	viewport.queue_free();await tree.process_frame
	return {"status":"PASS" if failures.is_empty() else "FAIL","checks":6,"failures":failures,"gpu_monster_motion":counts}
