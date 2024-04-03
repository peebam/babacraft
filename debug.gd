extends MeshInstance3D

func _process(delta: float) -> void:
	var _mesh : ImmediateMesh = mesh
	
	_mesh.clear_surfaces()
	_mesh.surface_end()
