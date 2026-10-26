class_name SceneLoader
extends RefCounted
## Single place that changes scenes, so every caller validates the path the same way.


## Changes to the scene at [param path]. Returns false (and warns) if it does not exist.
static func go_to(tree: SceneTree, path: String) -> bool:
	if not ResourceLoader.exists(path):
		push_warning("SceneLoader: scene not found: '%s'" % path)
		return false

	tree.change_scene_to_file(path)
	return true
