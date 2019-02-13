extends ScrollContainer

var content = [] setget set_content, get_content

var row_ref = null

func _ready():
	row_ref = get_node("List/Row")
	
func get_content():
	var result = []
	for d in content:
		var inside = {}
		inside["key"] = d.key
		if "index" in d:
			inside["index"] = d.index
		inside["name_id"] = d.obj.get_node("Choice/Name").bbcode_text
		inside["checked"] = d.obj.get_node("Choice").pressed
		result.push_back(inside)
	return result

func set_content(val):
	print(content)
	for d in content:
		d.obj.get_parent().remove_child(d.obj)
		d.obj.queue_free()
	content.clear()
	for v in val:
		var copy = row_ref.duplicate()
		copy.visible = true
		row_ref.get_parent().add_child(copy)
		if "index" in v:
			content.push_back({"obj": copy, "key": v.key, "index":v.index})
		else:	
			content.push_back({"obj": copy, "key": v.key})
		copy.get_node("Choice/Name").bbcode_text = v.name_id
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
