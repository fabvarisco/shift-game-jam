class_name EnemyShipGenerator
extends RefCounted

const ITEM_BLOCK := 0

## Fills grid_map with a ship interior layout and returns walkable floor cell positions
## valid for enemy spawning (back half of the ship).
static func generate(
	grid_map: GridMap,
	ship_width: int = 12,
	ship_depth: int = 8,
	seed_val: int = -1
) -> Array[Vector3i]:
	var rng := RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	grid_map.clear()
	var walkable: Array[Vector3i] = []

	# Floor layer (Y=0)
	for x in range(ship_width):
		for z in range(ship_depth):
			grid_map.set_cell_item(Vector3i(x, 0, z), ITEM_BLOCK)
			walkable.append(Vector3i(x, 0, z))

	# Perimeter walls (Y=1)
	for x in range(ship_width):
		grid_map.set_cell_item(Vector3i(x, 1, 0), ITEM_BLOCK)
		grid_map.set_cell_item(Vector3i(x, 1, ship_depth - 1), ITEM_BLOCK)
	for z in range(1, ship_depth - 1):
		grid_map.set_cell_item(Vector3i(0, 1, z), ITEM_BLOCK)
		grid_map.set_cell_item(Vector3i(ship_width - 1, 1, z), ITEM_BLOCK)

	# Interior divider wall with a single door gap
	var divider_z: int = ship_depth / 3
	var door_x: int = rng.randi_range(2, ship_width - 3)
	for x in range(1, ship_width - 1):
		if x != door_x:
			grid_map.set_cell_item(Vector3i(x, 1, divider_z), ITEM_BLOCK)
			walkable.erase(Vector3i(x, 0, divider_z))

	# Scatter interior pillars for cover
	var pillar_count: int = ship_width / 4
	for _i in range(pillar_count):
		var px: int = rng.randi_range(2, ship_width - 3)
		var pz: int = rng.randi_range(2, ship_depth - 2)
		if pz != divider_z:
			grid_map.set_cell_item(Vector3i(px, 1, pz), ITEM_BLOCK)
			walkable.erase(Vector3i(px, 0, pz))

	# Enemy spawn candidates: back half (z >= ship_depth/2)
	var spawns: Array[Vector3i] = []
	for cell in walkable:
		if cell.z >= ship_depth / 2:
			spawns.append(cell)
	spawns.shuffle()
	return spawns
