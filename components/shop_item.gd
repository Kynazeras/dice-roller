class_name ShopItem
extends Resource

@export var item_type: String = "" # "dice" | "modifier"
@export var item_id: String = ""
@export var cost: int = 0
@export var rarity: String = ""
@export var display_name: String = ""
@export var description: String = ""


static func from_dict(data: Dictionary) -> ShopItem:
	var item = ShopItem.new()
	item.item_type = data.get("item_type", "")
	item.item_id = data.get("item_id", "")
	item.cost = data.get("cost", 0)
	item.rarity = data.get("rarity", "")
	item.display_name = data.get("display_name", "")
	item.description = data.get("description", "")
	return item
