extends ScrollContainer

var content = [] setget set_content, get_content
var row_ref = null

signal OnChoiceDragAndDrop(container_src, container_dst, content_index_src)

func _ready():
	row_ref = get_node("List/Row")

#############	
#content ===> [{"src_key":"data/json/item/shield.json", "amount":1}]
#############
func get_content():
	var result = []
	for d in content:
		var inside = {}
		inside["src_key"] = d.src_key
		inside["amount"] = d.amount
		inside["checked"] = d.obj.get_node("Choice").pressed
		result.push_back(inside)
	return result

func set_content(val):
	for d in content:
		d.obj.get_parent().remove_child(d.obj)
		d.obj.queue_free()
	content.clear()
	for v in val:
		var copy = row_ref.duplicate()
		copy.visible = true
		row_ref.get_parent().add_child(copy)
		content.push_back({"obj": copy, "src_key":v.src_key, "amount":v.amount})
		var display = ""
		if v.src_key != null and v.src_key != "":
			var src_data = Globals.LevelLoaderRef.LoadJSON(v.src_key)
			if "stackable" in src_data.equipment and src_data.equipment.stackable == true:
				display = str(v.amount) + "x " + src_data.name_id
			else:
				display = src_data.name_id
		copy.get_node("Choice/Name").bbcode_text = display
		copy.get_node("Choice").MyData = {"origin":self, "content_index":content.size() - 1} # index in content array
	
func choice_can_drop_data(node_dest, data):
	if not "origin" in data:
		return false
	if data.origin == self:
		return false
	
	return true
	
func choice_drop_data(node_dest, data):
	#container_src, container_dst, content_index_src
	emit_signal("OnChoiceDragAndDrop", data.origin, self, data.content_index)