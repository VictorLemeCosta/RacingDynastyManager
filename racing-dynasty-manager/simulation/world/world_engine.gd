extends Node

class_name WorldEngine

const DataLoader = preload("res://scripts/core/data_loader.gd")

var database = {}

var world_state = {}


func initialize() -> void:

	database = DataLoader.load_database()

	world_state = {

		"currentDate": "2026-01-01",
		"currentSeason": 2026,

		"activeChampionships":
			database.get(
				"championships",
				{}
			).get(
				"championships",
				[]
			),

		"activeTeams":
			database.get(
				"teams",
				{}
			).get(
				"teams",
				[]
			),

		"activeDrivers":
			database.get(
				"drivers",
				{}
			).get(
				"drivers",
				[]
			),

		"activeStaff":
			database.get(
				"staff",
				{}
			).get(
				"staff",
				[]
			),

		"activeSponsors":
			database.get(
				"sponsors",
				{}
			).get(
				"sponsors",
				[]
			),

		"pendingEvents": [],
		"history": []
	}

	print("Banco carregado")


func advance_day() -> Array:
	return []
