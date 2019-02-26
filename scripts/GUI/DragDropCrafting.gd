extends ItemList

signal OnDropCrafting(origin, dest)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func get_drag_data(position):
	if get_selected_items().size() <= 0:
		return
		
	var selected_text = self.get_item_text(get_selected_items()[0])
	var node = Label.new()
	node.text = selected_text
	node.set_name("drag_label")
	set_drag_preview(node)
	return self
	
func can_drop_data(position, data):
	if (data.name == "Using" or data.name == "Need") and data.name != self.name:
		return true
		
	return false
	
func drop_data(position, data):
	emit_signal("OnDropCrafting", data, self)