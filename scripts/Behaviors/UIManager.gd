extends Node

export(NodePath) var animator = null

var _gui_list := {}
var _stack := []
var _animator : AnimationPlayer = null

func _ready():
	if animator != null:
		_animator = get_node(animator)
	BehaviorEvents.connect("OnGUILoaded", self, "OnGUILoaded_Callback")
	BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	BehaviorEvents.connect("OnShowGUI", self, "OnShowGUI_Callback")
	BehaviorEvents.connect("OnHideGUI", self, "OnHideGUI_Callback")
	

func OnShowGUI_Callback(name, init_param):
	_gui_list[name].visible = true
	_gui_list[name].Init(init_param)
	
func OnHideGUI_Callback(name):
	_gui_list[name].visible = false

func OnPlayerCreated_Callback(player):
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	# push default UI (might be some main menu or splash screen one day)
	BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "HUD", null)
	var cur_save = get_node("../LocalSave").get_latest_save()
	if cur_save == null or cur_save.empty():
		var player_name = player.get_attrib("player_name")
		BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "WelcomeScreen", {"player_name":player_name})
	else: # Middle of the game, tuto can start now. Start of game we wait till welcome screen is gone
		Globals.TutorialRef.emit_signal("StartTuto")
	
	BehaviorEvents.call_deferred("emit_signal", "OnLevelReady")

func OnGUILoaded_Callback(name, obj):
	# prevent adding duplicate that we create temporary for vfx
	if name in _gui_list:
		return
		
	_gui_list[name] = obj
	obj.visible = false
	
func OnPushGUI_Callback(name, init_param):
	#TODO: make sure Layout is not already in stack
	print("Push " + name)
	if _animator != null and _animator.is_playing():
		yield(_animator, "animation_finished")
	if _animator != null and _gui_list[name].Transition != false:
		var fx_viewport : Viewport = get_node("../../Camera-GUI/ViewportContainer/Viewport")
		fx_viewport.world_2d
		var fx_root : Node = _gui_list[name].GetVFXRoot().duplicate()
		fx_root.visible = true
		_gui_list[name].GetVFXRoot().visible = false
		_gui_list[name].VFXCopy = fx_root
		fx_viewport.add_child(fx_root)
		_animator.play("popin")
		_animator.connect("animation_finished", self, "animation_finished_Callback", [_gui_list[name], true])
		
	_gui_list[name].visible = true
	_update_shortcut(_gui_list[name])
	_gui_list[name].Init(init_param)
	if _stack.size() > 0:
		_gui_list[_stack[-1]].call_deferred("OnFocusLost")
	_stack.push_back(name)
	BehaviorEvents.emit_signal("OnGUIChanged", _stack[-1])
	
func OnPopGUI_Callback():
	print("Pop " + _stack[-1])
	if _animator != null and _gui_list[_stack[-1]].Transition != false:
		#_animator.root_node = _gui_list[_stack[-1]].get_path()
		
		var fx_viewport : Viewport = get_node("../../Camera-GUI/ViewportContainer/Viewport")
		var fx_root : Node = _gui_list[_stack[-1]].GetVFXRoot().duplicate()
		fx_root.visible = true
		_gui_list[_stack[-1]].GetVFXRoot().visible = false
		var old_parent : Node = fx_root.get_parent()
		_gui_list[_stack[-1]].VFXCopy = fx_root
		#old_parent.remove_child(fx_root)
		fx_viewport.add_child(fx_root)
		
		_animator.play_backwards("popin")
		_animator.connect("animation_finished", self, "animation_finished_Callback", [_gui_list[_stack[-1]], false])
	else:
		_gui_list[_stack[-1]].visible = false
	_stack.pop_back()
	if _stack.size() > 0:
		BehaviorEvents.emit_signal("OnGUIChanged", _stack[-1])
		_gui_list[_stack[-1]].call_deferred("OnFocusGained")
		
func _update_shortcut(node):
	for child in node.get_children():
		if child.has_method("RegisterShortcut"):
			child.RegisterShortcut()
		if child.get_child_count() > 0:
			_update_shortcut(child)

func animation_finished_Callback(anim_name, obj, vis):
	obj.visible = vis
	get_node("../../Camera-GUI/ViewportContainer").material.set_shader_param("alpha", 1.0);
	get_node("../../Camera-GUI/ViewportContainer").material.set_shader_param("pixel", 1.0);
	get_node("../../Camera-GUI/ViewportContainer").material.set_shader_param("red_offset", Vector2(0.0, 0.0));
	get_node("../../Camera-GUI/ViewportContainer").material.set_shader_param("green_offset", Vector2(0.0, 0.0));
	get_node("../../Camera-GUI/ViewportContainer").material.set_shader_param("blue_offset", Vector2(0.0, 0.0));
	
	if obj.VFXCopy != null:
		if obj.GetVFXRoot() != obj:
			obj.GetVFXRoot().visible = true
		obj.VFXCopy.get_parent().remove_child(obj.VFXCopy)
		obj.VFXCopy.queue_free()
		obj.VFXCopy = null
		
	_animator.disconnect("animation_finished", self, "animation_finished_Callback")
