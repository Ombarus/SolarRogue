extends ColorRect

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
func OnObjectLoaded_Callback(obj):
	if !obj.get_attrib("type") == "sun":
		return
		
	# defered because SpriteLoader will make the decision in idle_time because it sets materials
	call_deferred("check_palette", obj)

func check_palette(obj):
	var palette = obj.get_attrib("palette", "")
	var palette_list = obj.get_attrib("palettes", [])
	if palette.empty() or palette_list.empty():
		visible = false
		return
		
	for d in palette_list:
		if d["path"] == palette:
			var tone = d["tone"]
			var mult = d["multiplier"]
			var mult_vec = Vector3(mult[0], mult[1], mult[2])
			self.material.set_shader_param("Hue", tone[0])
			self.material.set_shader_param("Saturation", tone[1])
			self.material.set_shader_param("Brightness", tone[2])
			self.material.set_shader_param("multiplier", mult_vec)
			visible = true
			break
