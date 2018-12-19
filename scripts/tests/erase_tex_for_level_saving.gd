tool
extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(bool) var hide = false setget set_hide
export(bool) var show = false setget set_show
export(bool) var disable_tool = true setget set_tool

export(int) var gen_num = 4
export(Vector2) var start_offset = Vector2(640,640)

var _index = 0
var cur_x = 0
var cur_y = 0
var dx = 0
var dy = -1
onready var _orig_child_count = get_child_count()

func set_tool(newval):
	disable_tool = newval
	
func tool_disabled():
	return disable_tool

func set_hide(newval):
	hide = false
	for c in self.get_children():
		if c is Sprite:
			c.texture = null
			
func set_show(newval):
	show = false
	for c in self.get_children():
		if c is Sprite:
			c._refresh()
			
func _ready():
	var res = load("res://scripts/tests/mask_test.tres")
	#res.set_shader_param("test_color", Color(1.0,1.0,0.0,1.0))
	
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
    
	dynImage.create(80,80,false,Image.FORMAT_R8)
	_generate_visibility(dynImage)
    
	imageTexture.create_from_image(dynImage, 0)
	imageTexture.resource_name = "The created texture!"
	res.set_shader_param("bit_map", imageTexture)
	
	_generate_polygon(imageTexture)
	
func _generate_polygon(tex):
	var vertices = []
	var uv = []
	var fog_plane = get_parent().get_node("Fog")
	fog_plane.texture = tex
	fog_plane.material.set_shader_param("bit_map", tex)
	for x in range(80):
		vertices.push_back(Vector2((x*128),0))
		uv.push_back(Vector2(x, 0))
	for x in range(80):
		vertices.push_back(Vector2((79-x)*128, 128))
		uv.push_back(Vector2(79-x, 1))
	fog_plane.polygon = PoolVector2Array(vertices)
	fog_plane.uv = PoolVector2Array(uv)
	
	var dup_plane = null
	for y in range(1, 80):
		dup_plane = fog_plane.duplicate()
		var new_uv_ar = []
		for x in range(80):
			new_uv_ar.push_back(Vector2(x, y))
		for x in range(80):
			new_uv_ar.push_back(Vector2(79-x, y+1))
		dup_plane.uv = PoolVector2Array(new_uv_ar)
		dup_plane.position = Vector2(0, y * 128)
		fog_plane.call_deferred("add_child", dup_plane)
			
	#fog_plane.polygon = PoolVector2Array(vertices)

func _generate_visibility(dynImage):
	dynImage.lock()
	for x in range(80):
		for y in range(80):
			var rand_col = float(int(randf() * 255)) / 255.0
			dynImage.set_pixel(x, y, Color(rand_col, 0.0, 0.0, 0.0))
			#dynImage.set_pixel(x, y, Color(1.0,1.0,1.0))
	dynImage.unlock()
	print(var2str(dynImage.get_data()))
	#dynImage.save_png("res://test.png")
	

func _process(delta):
	if Engine.editor_hint == true:
		return
	if _index < _orig_child_count:
		get_children()[_index]._refresh()
		_index += 1
	else:
		var i = _index - _orig_child_count
		if i < gen_num * gen_num:
			var pos = Vector2((cur_x*256) + 128, (cur_y*256) + 128)
			if (pos.x > 0 and pos.x < start_offset.x) and (pos.y > 0 and pos.y < start_offset.y):
				pass
			else:
				var n = get_node("Multi").duplicate()
				n.star_seed = int(randf() * 10000)
				n.position = pos
				n._refresh()
				print("add_child (", i, "/", gen_num * gen_num, ") :", n)
				self.add_child(n)
			if cur_x == cur_y or (cur_x < 0 and cur_x == -cur_y) or (cur_x > 0 and cur_x == 1-cur_y):
				var tmp = dx
				dx = -dy
				dy = tmp
			cur_x = cur_x + dx
			cur_y = cur_y + dy
			_index += 1
