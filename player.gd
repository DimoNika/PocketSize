extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var scale_small = Vector3(0.5, 0.5, 0.5)
var scale_normal = Vector3(1, 1, 1)
var scale_big = Vector3(2, 2, 2)
var target_scale = Vector3.ONE
var start_scale = Vector3.ONE
var elapsed_time = 0.0
var duration = 1.0
var animating = false

	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if animating:
		elapsed_time += delta
		var t = clamp(elapsed_time / duration, 0, 1)
		scale = start_scale.lerp(target_scale, t)
		if t >= 1.0:
			animating = false
	
	if Input.is_action_just_pressed("deminish"):
		if scale == scale_big:
			start_scale = scale
			target_scale = scale_normal
			elapsed_time = 0.0
			animating = true
		if scale == scale_normal:
			start_scale = scale
			target_scale = scale_small
			elapsed_time = 0.0
			animating = true
			
	if Input.is_action_just_pressed("magnify"):
		if scale == scale_small:
			start_scale = scale
			target_scale = scale_normal
			elapsed_time = 0.0
			animating = true
		if scale == scale_normal:
			start_scale = scale
			target_scale = scale_big
			elapsed_time = 0.0
			animating = true
			
	#if Input.is_action_just_pressed("magnify"):
		#if scale == scale_small:
			#scale = scale_normal
		#elif scale == scale_normal:
			#scale = scale_big
			#
	#if Input.is_action_just_pressed("deminish"):		
		#if scale == scale_big:
			#var size_delta = (scale_big.x - scale_normal.x) / 60
			#while scale_normal.x < scale.x:
				#scale.x -= size_delta
				#scale.y -= size_delta
				#scale.z -= size_delta
			##scale = scale_normal
		#elif scale == scale_normal:
			#scale = scale_small
		
