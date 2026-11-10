extends RefCounted
## Real GPU readback: motion changes pixels; the quiet setting stays identical.
static func run(tree: SceneTree) -> Dictionary:
	var failures: Array[String]=[]
	var counts: Array=[]
	var viewport=SubViewport.new()
	viewport.size=Vector2i(256,192)
	viewport.world_2d=World2D.new()
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var sea=ColorRect.new();sea.size=Vector2(256,192)
	var material=ShaderMaterial.new();material.shader=preload("res://ocean.gdshader")
	material.set_shader_parameter("sea_tile",preload("res://assets/ui/painted/sea_tile.png"))
	material.set_shader_parameter("wave_noise",preload("res://assets/reference/ocean/wave_noise.png"))
	material.set_shader_parameter("viewport_size",Vector2(256,192))
	sea.material=material;viewport.add_child(sea)
	for classic in [true,false]:
		material.set_shader_parameter("web_classic",classic)
		for moving in [false,true]:
			material.set_shader_parameter("surface_motion",moving)
			for _frame in 3:await tree.process_frame
			await RenderingServer.frame_post_draw
			var first: PackedByteArray=viewport.get_texture().get_image().get_data()
			await tree.create_timer(.6 if moving else .2).timeout
			await RenderingServer.frame_post_draw
			var second: PackedByteArray=viewport.get_texture().get_image().get_data()
			var changed: int=0
			if first.size()!=second.size() or first.is_empty():failures.append("missing GPU image")
			else:
				for index in range(0,first.size(),16):
					if first[index]!=second[index] or first[index+1]!=second[index+1] or first[index+2]!=second[index+2]:changed+=1
			if moving and changed<20:failures.append("ocean did not animate")
			if not moving and changed!=0:failures.append("quiet ocean still moves")
			counts.append({"classic":classic,"motion":moving,"changed_samples":changed})
	viewport.queue_free();await tree.process_frame
	return {"status":"PASS" if failures.is_empty() else "FAIL","checks":4,"failures":failures,"gpu_ocean_motion":counts}
