extends RefCounted

class_name CalendarEngine


func advance_day(current_date: String) -> String:

	var parts = current_date.split("-")

	var year = int(parts[0])
	var month = int(parts[1])
	var day = int(parts[2])

	var days_in_month = _get_days_in_month(month, year)

	day += 1

	if day > days_in_month:
		day = 1
		month += 1

		if month > 12:
			month = 1
			year += 1

	return "%04d-%02d-%02d" % [
		year,
		month,
		day
	]


func _get_days_in_month(month: int, year: int) -> int:

	match month:

		1,3,5,7,8,10,12:
			return 31

		4,6,9,11:
			return 30

		2:
			if _is_leap_year(year):
				return 29

			return 28

	return 30


func _is_leap_year(year: int) -> bool:

	if year % 400 == 0:
		return true

	if year % 100 == 0:
		return false

	return year % 4 == 0
