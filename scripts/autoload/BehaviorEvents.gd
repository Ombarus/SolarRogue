extends Node


signal OnObjectLoaded(obj)
signal OnRequestObjectUnload(obj)
signal OnRequestLevelChange(level)
signal OnLevelLoaded()
signal OnMovement(obj, dir)
signal OnPositionUpdated(obj)
signal OnUseAP(obj, amount)
signal OnUseEnergy(obj, amount)
signal OnEnergyChanged(obj)
signal OnObjTurn(obj)
signal OnLogLine(text)
signal OnDealDamage(target, shooter, weapon_data)
signal OnDamageTaken(target, shooter)
signal OnPickup(picker, picked)
signal OnDropCargo(dropper, item_id)
signal OnDropMount(dropper, item_id)
signal OnAddItem(picker, item_id)
signal OnRemoveItem(holder, item_id)
signal OnScannerUpdated(obj)

signal OnGUILoaded(name, obj)
signal OnPushGUI(name, init_param)
signal OnPopGUI()


func _ready():
	pass
