extends Node

class_name WorldEngine

const DataLoader = preload("res://scripts/core/data_loader.gd")
const CalendarEngine = preload("res://simulation/world/calendar_engine.gd")
const EventEngine = preload("res://simulation/world/event_engine.gd")
const ChampionshipEngine = preload("res://simulation/championships/championship_engine.gd")

var database = {}
var event_engine = EventEngine.new()
var championship_engine = ChampionshipEngine.new()
var calendar_engine = CalendarEngine.new()
var world_state = {}


func initialize() -> void:

	database = DataLoader.load_database()

	world_state = {
	
		"playerCareer": {"currentChampionshipId":"champ_kart_indoor_sp",

		"reputation": 0,
		"currentRound": 0,
		"totalRounds": 0,
		"seasonPosition": 0
},
	
		"standings":championship_engine.initialize_standings(database.get("championships",{}).get("championships",[])
	),
		
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
	print(world_state.standings)
	generate_calendar_events()
	
	world_state["totalRounds"] = world_state.pendingEvents.size()


func advance_day() -> Array:

	world_state.currentDate = calendar_engine.advance_day(world_state.currentDate)

	return []

func continue_game() -> Array:

	var next_event = get_next_event()

	if next_event == null:

		return []

	world_state.pendingEvents.erase(next_event)

	world_state.currentDate = next_event["date"]

	world_state.history.append({
		"date": next_event["date"],
		"type": next_event["type"],
		"message":
			next_event["data"]["championship"]
	})

	if world_state.pendingEvents.is_empty():

		calculate_season_result()

	return [next_event]

func generate_calendar_events() -> void:

	for championship in world_state.activeChampionships:

		if championship.id != world_state.playerCareer.currentChampionshipId: continue

		for round_data in championship.get("calendar", []):

			var month = int(
				round_data.get("month", 1)
			)

			var round_num = int(
				round_data.get("round", 1)
			)

			var day = clamp(
				round_num * 3,
				1,
				28
			)

			var date = "%04d-%02d-%02d" % [
				world_state.currentSeason,
				month,
				day
			]

			var event = event_engine.create_event(
				"RACE_WEEKEND",
				date,
				{
					"championship":
						championship.get(
							"name",
							""
						),

					"track":
						round_data.get(
							"trackId",
							""
						)
				}
			)
			
			print("EVENTOS GERADOS:")
			print(world_state.pendingEvents)

			world_state.pendingEvents.append(event)

func get_next_event():

	var next_event = null

	for event in world_state.pendingEvents:

		if event["date"] > world_state.currentDate:

			if next_event == null:
				next_event = event

			elif event["date"] < next_event["date"]:
				next_event = event

	return next_event

func get_completed_rounds() -> int:

	var races = 0

	for item in world_state.history:

		if item.get("type", "") == "RACE_WEEKEND":
			races += 1

	return races

func calculate_season_result() -> void:

	var final_position = randi_range(1, 20)

	world_state.playerCareer.seasonPosition = final_position

	var reputation_gain = 0

	if final_position == 1:
		reputation_gain = 25

	elif final_position <= 3:
		reputation_gain = 15

	elif final_position <= 10:
		reputation_gain = 8

	else:
		reputation_gain = 3

	world_state.playerCareer.reputation += reputation_gain

	world_state.history.append({
		"type": "SEASON_FINISHED",
		"date": world_state.currentDate,
		"message":
			"Temporada encerrada - Posição "
			+ str(final_position)
			+ " | Reputação +"
			+ str(reputation_gain)
	})
