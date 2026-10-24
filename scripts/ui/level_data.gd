class_name LevelData
extends Resource
## One entry of the level selector: the scene, its display name and its preview image.

@export_file("*.tscn") var path: String = ""
## Display name. When empty, the scene file name is used.
@export var title: String = ""
## Optional preview image. Without it the card shows the level number.
@export var thumbnail: Texture2D


func get_display_title() -> String:
	if not title.is_empty():
		return title
	return path.get_file().get_basename().capitalize()
