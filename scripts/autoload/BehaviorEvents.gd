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
signal OnDealDamage(target, shooter, weapon_data) # fired before all other validations
signal OnShotFired(target, shooter, weapon_data) # for VFX
signal OnDamageTaken(target, shooter) # only fired if damage is > 0
signal OnPickup(picker, picked)
signal OnDropCargo(dropper, item_id)
signal OnDropMount(dropper, item_id)
signal OnEquipMount(equipper, slot_name, item_id)
signal OnAddItem(picker, item_id)
signal OnRemoveItem(holder, item_id)
signal OnScannerUpdated(obj)
signal OnPlayerDeath()
signal OnObjectDestroyed(obj) # for vfx
signal OnRequestPlayerTargetting(player, weapon_data, callback_obj, callback_method)
signal OnTargetClick(click_pos)
signal OnWaitForAnimation()
signal OnAnimationDone()

signal OnGUILoaded(name, obj)
signal OnPushGUI(name, init_param)
signal OnPopGUI()


func _ready():
	pass
