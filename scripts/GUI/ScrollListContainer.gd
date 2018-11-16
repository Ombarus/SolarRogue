extends ScrollContainer

var content setget set_content

var row_ref = null

func _ready():
	row_ref = get_node("List/Row")
	
func set_content(val):
	for v in val:
		var copy = row_ref.duplicate()
		copy.visible = true
		row_ref.get_parent().add_child(copy)
		copy.get_node("Choice/Name").bbcode_text = v.name_id
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
