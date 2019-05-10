extends Control

class_name MyItemList

# A scene that will be duplicated to add rows to the list
export(PackedScene) var Row
export(String) var DragDropID = ""
export(ButtonGroup) var SelectGroup = null
export(bool) var CanDropOnList = true
export(bool) var CanDropOnSelf = false

# takes an array of dictionnary information for row initialization
# returns an array of dictionary with information about row content
var Content setget set_content, get_content


signal OnDragDropCompleted(origin_data, destination_data)
signal OnSelectionChanged()

var _debug = false
onready var _rows_node = get_node("Rows")

func Clear():
	for row in _rows_node.get_children():
		_rows_node.remove_child(row)
		row.queue_free()

func set_content(val):
	Clear()
	var count = 0
	for row in val:
		var n = Row.instance()
		_rows_node.add_child(n)
		row["origin"] = self
		row["group"] = SelectGroup
		row["index"] = count
		row["dragdrop_id"] = DragDropID
		count += 1
		n.RowData = row
	
func get_content():
	var content = []
	for row in _rows_node.get_children():
		content.push_back(row.RowData)
	return content

func _ready():
	if _debug == true:
		set_content([{"text":"hello"}, {"text":"world long text"}, {"text":"bleh"}])

########### If row has Selectable Content ###############
func bubble_selection_changed():
	emit_signal("OnSelectionChanged")

########### DRAG & DROP ###############

func bubble_drop(orig_data, dst_data):
	emit_signal("OnDragDropCompleted", orig_data, dst_data)
	
func can_drop_data(position, data):
	return CanDropOnList and (CanDropOnSelf || data.origin != self) and self.DragDropID == data.dragdrop_id
	
func drop_data(position, data):
	emit_signal("OnDragDropCompleted", data, {"origin":self, "count":-1})
	