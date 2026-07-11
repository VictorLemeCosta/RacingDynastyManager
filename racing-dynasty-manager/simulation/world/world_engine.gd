extends Node

class_name WorldEngine

const DataLoader = preload("res://scripts/core/data_loader.gd")
const CalendarEngine = preload("res://simulation/world/calendar_engine.gd")
const EventEngine = preload("res://simulation/world/event_engine.gd")
const ChampionshipEngine = preload("res://simulation/championships/championship_engine.gd")
const RaceResultEngine = preload("res://simulation/race/race_result_engine.gd")

var database = {}
var event_engine = EventEngine.new()
var championship_engine = ChampionshipEngine.new()
var calendar_engine = CalendarEngine.new()
var world_state = {}
var race_result_engine = RaceResultEngine.new()


func initialize_database() -> void:
	database = DataLoader.load_database()

func advance_day() -> Array:

	world_state.currentDate = calendar_engine.advance_day(world_state.currentDate)

	return []

func continue_game() -> Array:

	var next_event = get_next_event()

	if next_event == null:
		return []

	world_state.pendingEvents.erase(next_event)

	world_state.currentDate = next_event["date"]

	var race_result = race_result_engine.simulate_player_result(
		world_state["playerCareer"]["reputation"]
	)
	
	var race_reputation = 0

	if race_result["position"] == 1:
		race_reputation = 3

	elif race_result["position"] <= 3:
		race_reputation = 2

	elif race_result["position"] <= 10:
		race_reputation = 1

	world_state["playerCareer"]["reputation"] += race_reputation

	world_state["playerCareer"]["seasonPoints"] += race_result["points"]

	world_state.raceResults.append({
		"date": next_event["date"],
		"eventType": next_event["type"],
		"championship": next_event["data"]["championship"],
		"track": next_event["data"]["track"],
		"position": race_result["position"],
		"points": race_result["points"]
	})

	var race_message = (
			next_event["data"]["championship"]
			+ " | Posição "
			+ str(race_result["position"])
			+ " | Pontos +"
			+ str(race_result["points"])
			+ " | Rep +"
			+ str(race_reputation)
		)

	world_state.history.append({
		"date": next_event["date"],
		"type": next_event["type"],
		"message": race_message
	})

	next_event["result"] = race_result
	next_event["summary"] = race_message

	if world_state.pendingEvents.is_empty():
		calculate_season_result()

	return [next_event]

func generate_calendar_events() -> void:
	
	print("CAMPEONATO ATUAL:")
	print(world_state["playerCareer"]["currentChampionshipId"])

	for championship in world_state.activeChampionships:
		
		print("CHAMP:")
		print(championship["id"])

		if championship["id"] != world_state["playerCareer"]["currentChampionshipId"]:
			continue
			
			print(championship)

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
			
			world_state.pendingEvents.append(event)
			
			print("EVENTO:")
			print(event)

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

	var points = world_state["playerCareer"]["seasonPoints"]

	var final_position = 20

	if points >= 100:
		final_position = 1

	elif points >= 75:
		final_position = 3

	elif points >= 50:
		final_position = 6

	elif points >= 25:
		final_position = 10

	elif points >= 10:
		final_position = 15

	else:
		final_position = 20

	world_state["playerCareer"]["seasonPosition"] = final_position

	var reputation_gain = 0

	if final_position == 1:
		reputation_gain = 25

	elif final_position <= 3:
		reputation_gain = 15

	elif final_position <= 10:
		reputation_gain = 8

	else:
		reputation_gain = 3

	world_state["playerCareer"]["reputation"] += reputation_gain

	world_state.history.append({
		"type": "SEASON_FINISHED",
		"date": world_state.currentDate,
		"message":
			"Temporada encerrada - Posição "
			+ str(final_position)
			+ " | Pontos "
			+ str(points)
			+ " | Reputação +"
			+ str(reputation_gain)
	})

func generate_dynamic_championships(player_career: Dictionary) -> Array:

	var result = []

	var templates = database.get(
		"championshipTemplates",
		{}
	).get(
		"templates",
		[]
	)

	for template in templates:

		var championship = build_dynamic_championship(
			template,
			player_career
		)

		result.append(championship)

	return result

func generate_dynamic_teams(player_career: Dictionary) -> Array:

	var result = []

	var templates = database.get(
		"teamTemplates",
		{}
	).get(
		"templates",
		[]
	)

	for template in templates:

		var team = build_dynamic_team(
			template,
			player_career
		)

		result.append(team)

	return result
	
func assign_starting_team() -> void:

	if world_state["activeTeams"].is_empty():
		return

	var selected_team = world_state["activeTeams"][0]

	world_state["playerCareer"]["teamId"] = selected_team["id"]

	print("Equipe inicial:")
	print(selected_team["name"])	
	
func get_player_team() -> Dictionary:

	var team_id = world_state["playerCareer"]["teamId"]

	for team in world_state["activeTeams"]:

		if team["id"] == team_id:
			return team

	return {}	
	
func build_dynamic_team(template: Dictionary, player_career: Dictionary) -> Dictionary:

	var team = template.duplicate(true)

	var city_slug = slugify(player_career["city"])

	team["id"] = (
		template["id"]
		+ "_"
		+ city_slug
	)

	team["name"] = replace_template_tokens(
		template["namePattern"],
		player_career
	)

	team["countryId"] = player_career["countryId"]

	team["championshipId"] = player_career["currentChampionshipId"]

	team["categoryId"] = template.get(
		"categoryId",
		"kart_indoor_regional"
	)

	return team

func build_dynamic_championship(template: Dictionary,player_career: Dictionary) -> Dictionary:

	var championship = template.duplicate(true)

	championship.erase("calendarTemplate")

	var city = player_career.get("city", "Unknown City")
	var country_id = player_career.get("countryId", "UNK")
	var country_adjective = player_career.get("countryAdjective", "National")

	var city_slug = slugify(city)
	var country_slug = country_id.to_lower()

	if int(template.get("tier", 1)) == 1:

		championship["id"] = (
				"dyn_regional_kart_indoor_"
				+ country_slug
				+ "_"
				+ city_slug
			)

	elif int(template.get("tier", 1)) == 2:

		championship["id"] = (
				"dyn_"
				+ str(template.get("id", "championship"))
				+ "_"
				+ country_slug
			)

	else:

		championship["id"] = (
				"dyn_regional_kart_indoor_"
				+ country_slug
				+ "_"
				+ city_slug
			)

	championship["name"] = replace_template_tokens(
		str(template.get("namePattern", template.get("name", ""))),
		player_career
	)

	championship["countryScope"] = [
		country_id
	]

	championship["generated"] = true

	championship["calendar"] = []

	for round_template in template.get("calendarTemplate", []):

		var round_data = {}

		round_data["round"] = round_template.get("round", 1)

		round_data["name"] = replace_template_tokens(
			str(round_template.get("namePattern", "Round")),
			player_career
		)

		round_data["month"] = round_template.get("month", 1)

		round_data["trackId"] = round_template.get(
	"trackId",
	"interlagos"
)

		championship["calendar"].append(round_data)

	return championship


func replace_template_tokens(
	text: String,
	player_career: Dictionary
) -> String:

	var result = text

	result = result.replace(
		"{city}",
		str(player_career.get("city", "Unknown City"))
	)

	result = result.replace(
		"{country}",
		str(player_career.get("countryId", "UNK"))
	)

	result = result.replace(
		"{countryAdjective}",
		str(player_career.get("countryAdjective", "National"))
	)

	return result


func slugify(value: String) -> String:

	var result = value.to_lower()

	result = result.replace(" ", "_")
	result = result.replace("-", "_")
	result = result.replace("ã", "a")
	result = result.replace("á", "a")
	result = result.replace("à", "a")
	result = result.replace("â", "a")
	result = result.replace("é", "e")
	result = result.replace("ê", "e")
	result = result.replace("í", "i")
	result = result.replace("ó", "o")
	result = result.replace("ô", "o")
	result = result.replace("õ", "o")
	result = result.replace("ú", "u")
	result = result.replace("ç", "c")

	return result

func get_available_starting_teams() -> Array:

	var result = []

	var current_championship_id = world_state["playerCareer"]["currentChampionshipId"]

	for team in world_state["activeTeams"]:

		if team.get("championshipId", "") != current_championship_id:
			continue
			
		var reputation = world_state["playerCareer"]["reputation"]

		if reputation < team.get( "minimumManagerReputation",0):
			continue

		result.append({
			"id": team["id"],
			"name": team["name"],
			"prestige": team.get("prestige", 0),
			"targetPosition": team.get("targetPosition", 20),
			"budget": team.get("budget", 0),
			"color": team.get("color", "#FFFFFF")
		})

	return result
	
func select_starting_team(team_id: String) -> bool:

	for team in world_state["activeTeams"]:

		if team["id"] == team_id:

			world_state["playerCareer"]["teamId"] = team_id

			print("Equipe selecionada:")
			print(team["name"])

			return true

	return false

func start_new_career(profile: Dictionary) -> void:

	var player_career = {
	"managerName": profile["managerName"],
	"countryId": profile["countryId"],
	"countryAdjective": profile["countryAdjective"],
	"city": profile["city"],
	"teamId": "",
	"currentChampionshipId": "",
	"currentTier": 1,
	"reputation": profile["startingReputation"],
	"seasonPosition": 0,
	"seasonPoints": 0
}

	var dynamic_championships = generate_dynamic_championships(player_career)

	if dynamic_championships.size() > 0:
		player_career["currentChampionshipId"] = dynamic_championships[0]["id"]

	var dynamic_teams = generate_dynamic_teams(player_career)

	var static_championships = database.get("championships", {}).get("championships", [])

	var all_championships = []
	all_championships.append_array(dynamic_championships)
	all_championships.append_array(static_championships)

	var static_teams = database.get("teams", {}).get("teams", [])

	var all_teams = []
	all_teams.append_array(dynamic_teams)
	all_teams.append_array(static_teams)

	world_state = {
		"playerCareer": player_career,
		"standings": championship_engine.initialize_standings(all_championships),
		"currentDate": "2027-01-01",
		"currentSeason": 2027,
		"activeChampionships": all_championships,
		"activeTeams": all_teams,
		"activeDrivers": database.get("drivers", {}).get("drivers", []),
		"activeStaff": database.get("staff", {}).get("staff", []),
		"activeSponsors": database.get("sponsors", {}).get("sponsors", []),
		"pendingEvents": [],
		"history": [],
		"raceResults": [],
		"totalRounds": 0
	}

	generate_calendar_events()

	world_state["totalRounds"] = world_state["pendingEvents"].size()
