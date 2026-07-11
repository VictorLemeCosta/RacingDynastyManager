extends Control

const WorldEngineScript = preload("res://simulation/world/world_engine.gd")

var world_engine

var selected_starting_reputation := 0

var manager_name_input: LineEdit
var country_selector: OptionButton
var city_input: LineEdit

var team_selector: OptionButton
var team_info: RichTextLabel
var available_teams := []

var date_label: Label
var next_event_label: RichTextLabel
var summary_label: RichTextLabel
var log_label: RichTextLabel


func _ready() -> void:
	world_engine = WorldEngineScript.new()
	add_child(world_engine)

	world_engine.initialize_database()

	show_career_level_screen()


func clear_screen() -> void:
	for child in get_children():
		if child != world_engine:
			child.queue_free()


func create_root() -> VBoxContainer:
	var root := VBoxContainer.new()

	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 32
	root.offset_top = 32
	root.offset_right = -32
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 16)

	add_child(root)

	return root


func create_title(text: String) -> Label:
	var title := Label.new()

	title.text = text
	title.add_theme_font_size_override("font_size", 30)

	return title


func create_card() -> PanelContainer:
	var card := PanelContainer.new()

	card.custom_minimum_size = Vector2(0, 120)

	return card


func show_career_level_screen() -> void:
	clear_screen()

	var root = create_root()

	root.add_child(
		create_title("Racing Dynasty Manager")
	)

	var subtitle := Label.new()
	subtitle.text = "Escolha o modo de início da carreira"
	subtitle.add_theme_font_size_override("font_size", 20)

	root.add_child(subtitle)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)

	root.add_child(buttons)

	var beginner_button := Button.new()
	beginner_button.text = "Manager Desconhecido (Rep 0)"
	beginner_button.custom_minimum_size = Vector2(200, 60)
	beginner_button.pressed.connect(
		func():
			selected_starting_reputation = 0
			show_manager_profile_screen()
	)

	buttons.add_child(beginner_button)

	var medium_button := Button.new()
	medium_button.text = "Ex-Piloto Profissional (Rep 50)"
	medium_button.custom_minimum_size = Vector2(200, 60)
	medium_button.pressed.connect(
		func():
			selected_starting_reputation = 50
			show_manager_profile_screen()
	)

	buttons.add_child(medium_button)

	var advanced_button := Button.new()
	advanced_button.text = "Lenda do Automobilismo (Rep 100)"
	advanced_button.custom_minimum_size = Vector2(200, 60)
	advanced_button.pressed.connect(
		func():
			selected_starting_reputation = 100
			show_manager_profile_screen()
	)

	buttons.add_child(advanced_button)


func show_manager_profile_screen() -> void:
	clear_screen()

	var root = create_root()

	root.add_child(
		create_title("Criação do Manager")
	)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	root.add_child(box)

	var name_label := Label.new()
	name_label.text = "Nome do manager"

	box.add_child(name_label)

	manager_name_input = LineEdit.new()
	manager_name_input.text = "Victor Costa"

	box.add_child(manager_name_input)

	var country_label := Label.new()
	country_label.text = "País"

	box.add_child(country_label)

	country_selector = OptionButton.new()

	country_selector.add_item("Brasil")
	country_selector.set_item_metadata(0, {
		"countryId": "BRA",
		"countryAdjective": "Brazilian",
		"defaultCity": "São Paulo"
	})

	country_selector.add_item("Croácia")
	country_selector.set_item_metadata(1, {
		"countryId": "CRO",
		"countryAdjective": "Croatian",
		"defaultCity": "Zagreb"
	})

	country_selector.add_item("Argentina")
	country_selector.set_item_metadata(2, {
		"countryId": "ARG",
		"countryAdjective": "Argentinian",
		"defaultCity": "Buenos Aires"
	})

	country_selector.add_item("Alemanha")
	country_selector.set_item_metadata(3, {
		"countryId": "DEU",
		"countryAdjective": "German",
		"defaultCity": "Berlin"
	})

	country_selector.item_selected.connect(_on_country_selected)

	box.add_child(country_selector)

	var city_label := Label.new()
	city_label.text = "Cidade"

	box.add_child(city_label)

	city_input = LineEdit.new()
	city_input.text = "São Paulo"

	box.add_child(city_input)

	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.pressed.connect(_on_profile_confirmed)

	box.add_child(continue_button)


func _on_country_selected(index: int) -> void:
	var data = country_selector.get_item_metadata(index)

	city_input.text = data["defaultCity"]


func _on_profile_confirmed() -> void:
	var country_data = country_selector.get_item_metadata(country_selector.selected)

	var profile = {

		"managerName": manager_name_input.text,
		"countryId": country_data["countryId"],
		"countryAdjective": country_data["countryAdjective"],
		"city": city_input.text,
		"startingReputation": selected_starting_reputation
	}

	world_engine.start_new_career(profile)

	show_team_selection_screen()


func show_team_selection_screen() -> void:
	clear_screen()

	var root = create_root()

	root.add_child(
		create_title("Escolha sua equipe inicial")
	)

	available_teams = world_engine.get_available_starting_teams()

	team_selector = OptionButton.new()
	team_selector.custom_minimum_size = Vector2(500, 50)

	for team in available_teams:
		team_selector.add_item(team["name"])

	team_selector.item_selected.connect(_on_team_selected)

	root.add_child(team_selector)

	team_info = RichTextLabel.new()
	team_info.custom_minimum_size = Vector2(0, 140)
	team_info.fit_content = true

	root.add_child(team_info)

	var sign_button := Button.new()
	sign_button.text = "Assinar Contrato"
	sign_button.custom_minimum_size = Vector2(260, 55)
	sign_button.pressed.connect(_on_sign_contract_pressed)

	root.add_child(sign_button)

	if available_teams.size() > 0:
		update_team_preview()


func _on_team_selected(index: int) -> void:
	update_team_preview()


func update_team_preview() -> void:
	if available_teams.is_empty():
		return

	var team = available_teams[team_selector.selected]

	team_info.text = (
		"Prestígio: "
		+ str(team["prestige"])
		+ "\nMeta da equipe: P"
		+ str(team["targetPosition"])
		+ "\nOrçamento: "
		+ str(team["budget"])
	)


func _on_sign_contract_pressed() -> void:
	if available_teams.is_empty():
		return

	var team = available_teams[team_selector.selected]

	world_engine.select_starting_team(
		team["id"]
	)

	show_dashboard_screen()


func show_dashboard_screen() -> void:
	clear_screen()

	var root = create_root()

	root.add_child(
		create_title("Racing Dynasty Manager")
	)

	var team = world_engine.get_player_team()
	var career = world_engine.world_state["playerCareer"]

	var manager_card = RichTextLabel.new()
	manager_card.fit_content = true
	manager_card.custom_minimum_size = Vector2(0, 110)

	manager_card.text = (
		"Manager: "
		+ career["managerName"]
		+ "\nPaís: "
		+ career["countryId"]
		+ "\nEquipe: "
		+ team.get("name", "Sem equipe")
		+ "\nReputação: "
		+ str(career["reputation"])
	)

	root.add_child(manager_card)

	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 18)

	root.add_child(date_label)

	next_event_label = RichTextLabel.new()
	next_event_label.fit_content = true
	next_event_label.custom_minimum_size = Vector2(0, 110)

	root.add_child(next_event_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)

	root.add_child(buttons)

	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.pressed.connect(_on_continue_pressed)

	buttons.add_child(continue_button)

	var next_race_button := Button.new()
	next_race_button.text = "Próxima Corrida"
	next_race_button.pressed.connect(_on_continue_pressed)

	buttons.add_child(next_race_button)

	summary_label = RichTextLabel.new()
	summary_label.fit_content = true
	summary_label.custom_minimum_size = Vector2(0, 150)

	root.add_child(summary_label)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 260)

	root.add_child(log_label)

	_refresh_ui([])


func _on_continue_pressed() -> void:
	var events = world_engine.continue_game()

	_refresh_ui(events)


func _refresh_ui(events: Array) -> void:
	var state = world_engine.world_state

	date_label.text = (
		"Data atual: "
		+ state["currentDate"]
		+ " | Temporada: "
		+ str(state["currentSeason"])
		+ " | Corrida "
		+ str(world_engine.get_completed_rounds())
		+ "/"
		+ str(state["totalRounds"])
	)

	var next_event = world_engine.get_next_event()

	next_event_label.text = ""

	if next_event == null:
		next_event_label.append_text(
			"Temporada Encerrada\n"
		)

		next_event_label.append_text(
			"Posição Final: "
			+ str(state["playerCareer"]["seasonPosition"])
			+ "\nReputação: "
			+ str(state["playerCareer"]["reputation"])
		)
	else:
		next_event_label.append_text(
			"Próximo Evento\n"
		)

		next_event_label.append_text(
			"Data: "
			+ str(next_event["date"])
			+ "\nTipo: "
			+ str(next_event["type"])
			+ "\nCampeonato: "
			+ str(next_event["data"]["championship"])
			+ "\nPista: "
			+ str(next_event["data"]["track"])
		)

	summary_label.text = ""
	summary_label.append_text("Resumo do mundo carregado\n")
	summary_label.append_text("Campeonatos ativos: " + str(state["activeChampionships"].size()) + "\n")
	summary_label.append_text("Equipes ativas: " + str(state["activeTeams"].size()) + "\n")
	summary_label.append_text("Pilotos ativos: " + str(state["activeDrivers"].size()) + "\n")
	summary_label.append_text("Eventos pendentes: " + str(state["pendingEvents"].size()) + "\n")

	log_label.text = ""
	log_label.append_text("Histórico recente\n")

	var history = state.get("history", [])

	var start_index = max(0, history.size() - 10)

	for i in range(start_index, history.size()):
		var item = history[i]

		log_label.append_text(
			str(item.get("date", ""))
			+ " | "
			+ str(item.get("type", ""))
			+ " | "
			+ str(item.get("message", ""))
			+ "\n"
		)
