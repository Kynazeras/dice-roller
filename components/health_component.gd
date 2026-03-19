class_name HealthComponent
extends Node

# Thank you to ZauraGS for this health component
# https://github.com/ZauraGS/HealthComponent/blob/main/Components/Health/health_component.gd


enum TYPE { DAMAGE, HEALING, RESURRECTION }

signal health_changed(current_amount: int, max_amount: int)
signal damaged(amount: int)
signal healed(amount: int)
signal resurrected
signal died(overkill: int)

@export var max_health: int = 25
@export var god_mode: bool = false
var current_health: int = max_health :
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
var dead: bool = false


func take_damage(damage: int) -> void:
	_change_health(damage, TYPE.DAMAGE)


func take_healing(healing: int) -> void:
	_change_health(healing, TYPE.HEALING)


func resurrect(healing: int) -> void:
	_change_health(healing, TYPE.RESURRECTION)


func _change_health(amount: int, type: TYPE) -> void:
	match type:
		TYPE.HEALING:
			if dead:
				return
			current_health += amount
			healed.emit(amount)
		TYPE.RESURRECTION:
			if not dead:
				return
			dead = false
			current_health += amount
			healed.emit(amount)
			resurrected.emit()
		TYPE.DAMAGE:
			if god_mode:
				return
			var overkill: int = amount - current_health
			current_health -= amount
			damaged.emit(amount)
			if current_health <= 0:
				dead = true
				died.emit(overkill)