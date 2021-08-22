extends Node


signal OnObjectLoaded(obj)
signal OnRequestObjectUnload(obj)
signal OnRequestLevelChange(level)
signal OnStartLoadLevel()
signal OnLevelLoaded()
signal OnLevelReady()
signal OnPlayerCreated(player)
signal OnAttributeAdded(obj, added_name)
signal OnCameraDragged()
signal OnCameraZoomed(new_zoom)
signal OnMovement(obj, dir)
signal OnMovementValidated(obj, dir)
signal OnTeleport(obj, prev_tile, new_tile)
signal OnPositionUpdated(obj)
signal OnBeginParallelAction(obj)
signal OnUseAP(obj, amount)
signal OnAPUsed(obj, amount) # To lock player input as soon as it has done an action (the action will be validated by the APBehavior in case of complex, parallel events)
signal OnEndParallelAction(obj)
signal OnUseEnergy(obj, amount)
signal OnEnergyChanged(obj)
signal OnObjTurn(obj)
signal OnPlayerTurn(obj)
signal OnLogLine(text, fmt)
signal OnDealDamage(targets, shooter, weapon_data, modified_attributes, shot_tile) # fired before all other validations
signal OnShotFired(shot_tile, shooter, weapon_data) # for VFX
signal OnDamageTaken(target, shooter, damage_type) # only fired if damage is > 0
signal OnPickup(picker, picked)
signal OnObjectsPicked(picker)
signal OnPickObject(picker, obj)
signal OnPickItem(picker, item_id, modified_attributes) # called before adding item to iventory to give chance to apply effects
signal OnDropCargo(dropper, item_id, variation_src, count)
signal OnItemDropped(dropper, item_id, modified_attributes)
signal OnDropMount(dropper, item_id, index)
signal OnRemoveMount(dropper, item_id, index)
signal OnEquipMount(equipper, slot_name, index, item_id, variation_src)
signal OnAddItem(picker, item_id, modified_attributes)
signal OnRemoveItem(holder, item_id, modified_attributes, amount)
signal OnMoveCargo(from, to)
signal OnTradingDone(shipa, shipb)
signal OnScannerUpdated(obj)
signal OnPlayerDeath(player)
signal OnObjectDestroyed(obj) # for vfx
signal OnRequestTargettingOverlay(player, targetting_data, callback_obj, callback_method)
signal OnTargetClick(click_pos, target_type)
signal OnWaitForAnimation()
signal OnAnimationDone()
signal OnTransferPlayer(old_player, new_player)
signal OnMountRemoved(obj, slot, src, modified_attributes)
signal OnMountAdded(obj, slot, src, modified_attributes)
signal OnClearMounts(obj)
signal OnClearCargo(obj)
signal OnReplaceCargo(obj, new_cargo)
signal OnUpdateCargoVolume(obj)
signal OnConsumeItem(obj, item_data, key, attrib)
signal OnValidateConsumption(obj, item_data, key, attrib)
signal OnUpdateInvAttribute(obj, item_id, old_attrib, new_attrib)
signal OnUpdateMountAttribute(obj, key, idx, new_attrib)
signal OnTriggerAnomaly(obj, anomaly)
signal OnAnomalyEffectGone(obj, effect_data)
signal OnCrafting(crafter, result)
signal OnResumeCrafting(crafter)
signal OnCancelCrafting(crafter)
signal OnStatusChanged(obj)
signal OnDifficultyChanged(newdiff)
signal OnPlayerInputStateChanged(playerObj, inputState)
signal OnAddToAnimationQueue(callback_obj, callback_name, args, priority)
signal OnScannerPickup(type)
signal OnDoubleTap()
signal OnSystemDisabled(obj, system)
signal OnSystemEnabled(obj, system)
signal OnResumeAttack()

signal OnGUILoaded(name, obj)
signal OnPushGUI(name, init_param, transition_name)
signal OnPopGUI()
signal OnShowGUI(name, init_param, transition) # will not add the menu on the stack
signal OnHideGUI(name)
signal OnAddShortcut(key, obj, method)
signal OnRemoveShortcut(key, obj, method)
signal OnEnableShortcut(key, obj, method, isEnabled)
signal OnGUIChanged(current_menu)
signal OnHighlightUIElement(element_name)
signal OnResetHighlight()
signal OnHUDVisiblityChanged()
signal OnLocaleChanged()
signal OnHUDCreated()

signal OnButtonReady(btn)
signal OnHUDWeaponPressed
signal OnHUDGrabPressed
signal OnHUDInventoryPressed
signal OnHUDFTLPressed
signal OnHUDCraftingPressed
signal OnHUDLookPressed
signal OnHUDBoardPressed
signal OnHUDTakePressed
signal OnHUDWaitPressed
signal OnHUDCrewPressed
signal OnHUDCommPressed
signal OnHUDOptionPressed
signal OnHUDQuestionPressed


func _ready():
	pass
