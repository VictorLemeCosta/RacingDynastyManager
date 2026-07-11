extends RefCounted

class_name ChampionshipEngine


func initialize_standings(championships: Array) -> Dictionary:

	var standings = {}

	for championship in championships:

		standings[
			championship.id
		] = {

			"name": championship.name,

			"driver_points": {},

			"team_points": {}
		}

	return standings
