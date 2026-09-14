class_name DataDir
extends RefCounted


static func load_all(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var files := DirAccess.get_files_at(dir_path)
	files.sort()
	for file in files:
		# Exported builds may remap .tres files to .tres.remap; the loader still resolves the original path.
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		resources.append(load(dir_path.path_join(name)))
	return resources
