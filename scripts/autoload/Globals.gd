extends Node

var LevelLoaderRef = null
var last_delta_turn = 0
var total_turn = 0

enum CRAFT_RESULT {
	success,
	not_enough_resources,
	not_enough_energy,
	missing_resources
}

func _ready():
	pass
