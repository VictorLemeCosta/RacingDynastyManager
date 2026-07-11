extends RefCounted

class_name RaceResultEngine


func simulate_player_result(player_reputation: int) -> Dictionary:

	var base_roll = randi_range(1, 20)

	var reputation_bonus = int(player_reputation / 10)

	var final_position = base_roll - reputation_bonus

	final_position = clamp(final_position, 1, 20)

	var points = get_points_for_position(final_position)

	return {
		"position": final_position,
		"points": points
	}


func get_points_for_position(position: int) -> int:

	var points_table = {
		1: 25,
		2: 18,
		3: 15,
		4: 12,
		5: 10,
		6: 8,
		7: 6,
		8: 4,
		9: 2,
		10: 1
	}

	return points_table.get(position, 0)
