extends RefCounted

class_name EventEngine


func create_event(
	event_type: String,
	event_date: String,
	event_data: Dictionary = {}
) -> Dictionary:

	return {
		"type": event_type,
		"date": event_date,
		"data": event_data
	}
