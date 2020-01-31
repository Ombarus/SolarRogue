extends Node2D

export(PackedScene) var FXScene

func instanciate():
	var n = FXScene.instance() # this scene should be self-deleting
	self.add_child(n)
