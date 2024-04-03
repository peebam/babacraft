extends Object
class_name Chrono

var _start_time := Time.get_ticks_msec()


func print_overall_elapsed_time_ms(description := "") -> void:
	var last := Time.get_ticks_msec() - _start_time
	if description == "":
		prints(last, "ms")
		return

	prints(description, last, "ms")

