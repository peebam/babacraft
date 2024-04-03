class_name WorldBuilder
extends Node3D

signal chunk_built(chunk_builder: ChunkBuilder)
signal chunk_disposed(chunk_coordinates: Vector2i)

var _chunk_center_coordinates := Vector2i.ZERO

var _chunks_to_display : Array[ChunkBuilder] = []
var _chunks_to_display_mutex := Mutex.new()

var _chunks_to_dispose : Array[Vector2i] = []
var _chunks_to_dispose_mutex := Mutex.new()

var _load_threads : Array[Thread] = []
var _semaphores : Array[Semaphore] = []

var _thread_cancel_loop : Array[bool] = []
var _thread_cancel_loop_mutex : Array[Mutex] = []

var _thread_exit := false
var _thread_exit_mutex := Mutex.new()

# Built-in

func _ready() -> void:
	_load_threads.resize(Global.NB_THREADS)
	_semaphores.resize(Global.NB_THREADS)
	_thread_cancel_loop.resize(Global.NB_THREADS)
	_thread_cancel_loop_mutex.resize(Global.NB_THREADS)

	var load_diameter := 1 + Global.LOAD_RADIUS * 2
	var nb_chunks = load_diameter * load_diameter
	var nb_chunks_per_thread = floor(nb_chunks / Global.NB_THREADS)

	for i in Global.NB_THREADS:
		_load_threads[i] = Thread.new()
		_semaphores[i] = Semaphore.new()
		_thread_cancel_loop_mutex[i] = Mutex.new()
		_thread_cancel_loop[i] = false

		if i == Global.NB_THREADS - 1:
			var chunks_range := range(i * nb_chunks_per_thread, nb_chunks)
			_load_threads[i].start(_thread_process.bind(i, chunks_range))
			continue

		var chunks_range := range(i * nb_chunks_per_thread, i * nb_chunks_per_thread + nb_chunks_per_thread)
		_load_threads[i].start(_thread_process.bind(i, chunks_range))


func _process(_delta: float) -> void:
	if _chunks_to_dispose_mutex.try_lock():
		for chunk_coordinates in _chunks_to_dispose:
			chunk_disposed.emit(chunk_coordinates)
		_chunks_to_dispose.clear()
		_chunks_to_dispose_mutex.unlock()

	if _chunks_to_display_mutex.try_lock():
		var chunk_builder :ChunkBuilder = _chunks_to_display.pop_front()
		_chunks_to_display_mutex.unlock()
		if chunk_builder != null:
			chunk_built.emit(chunk_builder)


func _exit_tree() -> void:
	_thread_exit_mutex.lock()
	_thread_exit = true
	_thread_exit_mutex.unlock()

	for i in Global.NB_THREADS:
		_semaphores[i].post()
		_load_threads[i].wait_to_finish()

# Private

func _cancel_all_threads_loop() -> void:
	for i in Global.NB_THREADS:
		_cancel_thread_loop(i)


func _cancel_thread_loop(thread_number : int) -> void:
	if _thread_cancel_loop_mutex[thread_number].try_lock():
		_thread_cancel_loop[thread_number] = true
		_thread_cancel_loop_mutex[thread_number].unlock()


func _is_thread_loop_canceled(thread_number : int) -> bool:
	if _thread_cancel_loop_mutex[thread_number].try_lock():
		var cancel_loop := _thread_cancel_loop[thread_number]
		_thread_cancel_loop[thread_number] = false
		_thread_cancel_loop_mutex[thread_number].unlock()
		return cancel_loop
	return false


func _thread_process(thread_number : int, chunks_range) -> void:
	var chunks: Dictionary = {}

	print("Thread #", thread_number, " - chunks: ", chunks_range)

	while(true):
		if _thread_must_exit():
			return

		var preparations : Array[Dictionary] = []

		for i in chunks_range:
			var chunk_exists = chunks.has(i)
			var current_coordinates = chunks[i] if chunk_exists else Global.int_to_coordinates(i)

			var cx: int = current_coordinates.x
			var cz: int = current_coordinates.y
			var px: int = _chunk_center_coordinates.x
			var pz: int = _chunk_center_coordinates.y

			var coordinates := Vector2i(
				posmod(cx - px + Global.LOAD_RADIUS, 1 + Global.LOAD_RADIUS * 2) + px - Global.LOAD_RADIUS,
				posmod(cz - pz + Global.LOAD_RADIUS, 1 + Global.LOAD_RADIUS * 2) + pz - Global.LOAD_RADIUS
			)

			if !chunk_exists or current_coordinates != coordinates:

				preparations.append({
					"coordinates": coordinates,
					"distance_to_center": Vector2(_chunk_center_coordinates).distance_to(Vector2(coordinates)),
					"exists": chunk_exists,
					"previous_coordinates": current_coordinates,
				})
				chunks[i] = coordinates

		print(preparations.size())
		if preparations.is_empty():
			print("Thread #", thread_number, " sleeps")
			_semaphores[thread_number].wait()
			print("Thread #", thread_number, " wakes up")

		preparations.sort_custom(func(a : Dictionary, b : Dictionary) -> bool: return a.distance_to_center < b.distance_to_center)
		for preparation in preparations:
			if _thread_must_exit():
				return

			if _is_thread_loop_canceled(thread_number):
				break

			var chrono := Chrono.new()

			var chunk_builder:= ChunkBuilder.new()
			chunk_builder.init(preparation.coordinates)
			chunk_builder.generate()
			chunk_builder.prepare()

			chrono.print_overall_elapsed_time_ms("Chunk generated")

			_chunks_to_display_mutex.lock()
			_chunks_to_display.push_back(chunk_builder)
			_chunks_to_display_mutex.unlock()

			if preparation.exists:
				_chunks_to_dispose_mutex.lock()
				_chunks_to_dispose.push_back(preparation.previous_coordinates)
				_chunks_to_dispose_mutex.unlock()


func _thread_must_exit() -> bool:
	if _thread_exit_mutex.try_lock():
		var exit := _thread_exit
		_thread_exit_mutex.unlock()
		return exit
	return false

# Public

func set_chunk_center_coordinates(chunk_coordinates: Vector2i):
	_chunk_center_coordinates = chunk_coordinates
	for i in Global.NB_THREADS:
		_semaphores[i].post()


