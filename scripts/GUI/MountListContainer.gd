extends ScrollContainer

var content = [] setget set_content, get_content
var row_ref = null

signal OnChoiceDragAndDrop(container_src, container_dst, content_index_src)

func _ready():
	row_ref = get_node("List/Row")

#############	
#content ===> [{"mount_key":"small_weapon", "src_key":"data/json/item/shield.json"}]
#############
func get_content():
	var result = []
	for d in content:
		var inside = {}
		inside["mount_key"] = d.mount_key
		inside["src_key"] = d.src_key
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
		content.push_back({"obj": copy, "mount_key": v.mount_key, "src_key":v.src_key})
		var display = v.mount_key + " : Free"
		if v.src_key != null and v.src_key != "":
			var src_data = Globals.LevelLoaderRef.LoadJSON(v.src_key)
			display = v.mount_key + " : " + src_data.name_id
		copy.get_node("Choice/Name").bbcode_text = display
		copy.get_node("Choice").MyData = {"origin":self, "content_index":content.size() - 1} # index in content array
		#copy.get_node("Choice").connect("toggled", self, "toggled_callback", [v.mount_key, v.src_key])
	
func choice_can_drop_data(node_dest, data):
	if not "origin" in data:
		return false
	if data.origin == self:
		return false
	var dest_content_data = get_content()[node_dest.MyData.content_index]
	var src_content_data = data.origin.get_content()[data.content_index]
	var canMount = true
	
	#"equipment": {
	#	"slot":"small_weapon_mount",
	#	"volume":100.0
	#}
	
	#TODO: check if item dragged from cargo fits into dest mount
	if not "mount_key" in src_content_data:
		var src_data = Globals.LevelLoaderRef.LoadJSON(src_content_data.src_key)
		if not "slot" in src_data.equipment or src_data.equipment.slot != dest_content_data.mount_key:
			canMount = false
	
	if "mount_key" in src_content_data and dest_content_data.mount_key != src_content_data.mount_key:
		canMount = false
	
	return canMount
	
func choice_drop_data(node_dest, data):
	#container_src, container_dst, content_index_src
	emit_signal("OnChoiceDragAndDrop", data.origin, self, data.content_index)
