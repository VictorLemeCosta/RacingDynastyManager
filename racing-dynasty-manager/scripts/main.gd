extends Control

const WorldEngineScript = preload("res://simulation/world/world_engine.gd")

var world_engine
var date_label: Label
var summary_label: RichTextLabel
var log_label: RichTextLabel


func _ready() -> void:
	world_engine = WorldEngineScript.new()
	add_child(world_engine)
	world_engine.initialize()

	_build_ui()
	_refresh_ui([])


func _build_ui() -> void:
	var root := VBoxContainer.new()

	root.name = "RootLayout"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 24
	root.offset_top = 24
	root.offset_right = -24
	root.offset_bottom = -24

	root.add_theme_constant_override("separation", 12)

	add_child(root)

	var title := Label.new()
	title.text = "Racing Dynasty Manager - Godot Starter"
	title.add_theme_font_size_override("font_size", 26)

	root.add_child(title)

	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 18)

	root.add_child(date_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)

	root.add_child(buttons)

	var advance_button := Button.new()
	advance_button.text = "Avançar 1 dia"
	advance_button.pressed.connect(_on_advance_day_pressed)

	buttons.add_child(advance_button)

	var advance_week_button := Button.new()
	advance_week_button.text = "Avançar 7 dias"
	advance_week_button.pressed.connect(_on_advance_week_pressed)

	buttons.add_child(advance_week_button)

	summary_label = RichTextLabel.new()
	summary_label.fit_content = true
	summary_label.custom_minimum_size = Vector2(0, 170)

	root.add_child(summary_label)

	log_label = RichTextLabel.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	root.add_child(log_label)


func _on_advance_day_pressed() -> void:
	var events = world_engine.advance_day()
	_refresh_ui(events)


func _on_advance_week_pressed() -> void:
	var all_events = []

	for i in range(7):
		all_events.append_array(world_engine.advance_day())

	_refresh_ui(all_events)


func _refresh_ui(events: Array) -> void:
	var state = world_engine.world_state

	date_label.text = "Data atual: " + state.currentDate + " | Temporada: " + str(state.currentSeason)

	summary_label.text = ""
	summary_label.append_text("[b]Resumo do mundo carregado[/b]\n")
	summary_label.append_text("Campeonatos ativos: " + str(state.activeChampionships.size()) + "\n")
	summary_label.append_text("Equipes ativas: " + str(state.activeTeams.size()) + "\n")
	summary_label.append_text("Pilotos ativos: " + str(state.activeDrivers.size()) + "\n")
	summary_label.append_text("Staff ativo: " + str(state.activeStaff.size()) + "\n")
	summary_label.append_text("Patrocinadores ativos: " + str(state.activeSponsors.size()) + "\n")
	summary_label.append_text("Eventos pendentes: " + str(state.pendingEvents.size()) + "\n")

	log_label.text = ""
	log_label.append_text("[b]Eventos processados agora[/b]\n")

	if events.is_empty():
		log_label.append_text("Nenhum evento nesta data.\n")
	else:
		for event in events:
			log_label.append_text(
				"- "
				+ str(event.get("type", "EVENT"))
				+ ": "
				+ str(event.get("roundName", ""))
				+ "\n"
			)

	log_label.append_text("\n[b]Histórico recente[/b]\n")

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
