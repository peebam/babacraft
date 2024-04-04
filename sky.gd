@tool
extends WorldEnvironment

signal time_of_day_set

const TIME_OF_DAY_NB_HOURS := 2400.0

@export var sky_top_color : GradientTexture1D
@export var sky_horizon_color : GradientTexture1D
@export var sun_light_color : GradientTexture1D

@export_range(0, TIME_OF_DAY_NB_HOURS, 0.01) var time_of_day := 1200.0 :
	set = set_time_of_day

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_time_of_day(value: float):
	if value < 0.0 or value >= TIME_OF_DAY_NB_HOURS:
		return

	if value == time_of_day:
		return

	time_of_day = value
	time_of_day_set.emit()


func _on_time_of_day_set() -> void:
	var day_progression := time_of_day / TIME_OF_DAY_NB_HOURS
	$SunMoon.rotation.x = lerp(-PI * 1.5, PI * 0.5, day_progression)

	var sky_material: ProceduralSkyMaterial = environment.sky.sky_material
	sky_material.set_sky_top_color(sky_top_color.gradient.sample(day_progression))
	sky_material.sky_horizon_color = sky_horizon_color.gradient.sample(day_progression)
	$SunMoon/Sun.light_color = sun_light_color.gradient.sample(day_progression)
	environment.ambient_light_color = sky_material.sky_horizon_color
