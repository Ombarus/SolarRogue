extends Node

var BaseObject = preload("res://scenes/object.tscn")
var TargettingReticle = preload("res://scenes/tileset_source/targetting_reticle.tscn")

var EnTable = preload("res://data/translation/base.en.translation")
var JaTable = preload("res://data/translation/base.ja.translation")
var FrTable = preload("res://data/translation/base.fr.translation")

var JsonCache = {}
