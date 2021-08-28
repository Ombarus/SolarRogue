extends Node2D

export(Rect2) var SpriteCoord

var _target_ref = null

func Start(target):
	_target_ref = target
	var crafted_data = target.get_attrib("animation.crafted")
	SpriteCoord = Rect2(crafted_data[0],crafted_data[1],crafted_data[2],crafted_data[3])
	get_node("Sprite").region_rect = SpriteCoord
	get_node("AnimationPlayer").play("craft")

func AnimationEnd():
	if _target_ref != null:
		_target_ref.visible = true
		_target_ref.modulate.a = 1.0
		self.visible = false
		BehaviorEvents.emit_signal("OnAnimationDone")
		get_parent().remove_child(self)
		queue_free()
