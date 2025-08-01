extends CharacterBody3D

@export var blend_speed = 15

enum { IDLE, RUN, JUMP }
var curAnim = IDLE

var run_val = 0
var jump_val = 0
var move_dir = Vector2(velocity.x, velocity.z)

@onready var camera = get_viewport().get_camera_3d()
@onready var anim_tree : AnimationTree = $Gnome/AnimationTree 
@onready var armature = $Gnome/Armature

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var has_magnifying_gem = false
var has_deminishing_gem = false


var scale_small = Vector3(0.5, 0.5, 0.5)
var scale_normal = Vector3(1, 1, 1)
var scale_big = Vector3(2, 2, 2)
var target_scale = Vector3.ONE
var start_scale = Vector3.ONE
var elapsed_time = 0.0
var duration = 1.0
var animating = false

	
func pick_deminishing_gem():
	has_deminishing_gem = true
	
func pick_magnifying_gem():
	has_magnifying_gem = true

# АНИМАЦИЯ
func handle_animations(delta):
	match curAnim:
		IDLE:
			run_val = lerpf(run_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
		RUN:
			run_val = lerpf(run_val, 1, blend_speed * delta)
			jump_val = lerpf(jump_val, 0, blend_speed * delta)
		JUMP:
			run_val = lerpf(run_val, 0, blend_speed * delta)
			jump_val = lerpf(jump_val, 1, blend_speed * delta)
	update_tree()

func update_tree():
	anim_tree["parameters/Run/blend_amount"] = run_val
	anim_tree["parameters/Jump/blend_amount"] = jump_val

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	# Если мы на земле и нажали прыжок, или если мы в воздухе и не в состоянии прыжка (например, упали)
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		curAnim = JUMP
	elif not is_on_floor() and curAnim != JUMP:
		curAnim = JUMP

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if camera:
		# Рассчитываем направление относительно камеры
		var camera_forward = -camera.global_transform.basis.z
		camera_forward.y = 0
		camera_forward = camera_forward.normalized()

		var camera_right = camera.global_transform.basis.x
		camera_right.y = 0
		camera_right = camera_right.normalized()

		direction = (camera_forward * input_dir.y) + (camera_right * input_dir.x)
		direction = direction.normalized()
	
	if is_on_floor() and move_dir.length() > 0.1:
		var target_angle = atan2(-velocity.x, -velocity.z)
		armature.rotation.y = lerp_angle(armature.rotation.y, target_angle, 0.15)
	
	# Обновление скорости для движения
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	

	move_and_slide() # Перемещаем и обновляем is_on_floor()

	if direction.length() > 0.1:
		# Вычисляем угол поворота в плоскости XZ
		var look_direction = Vector2(direction.x, direction.y)
		var target_angle = look_direction.angle()
		armature.rotation.y = lerp_angle(armature.rotation.y, target_angle, 15 * delta)
	# <-- КОРРЕКЦИЯ ЛОГИКИ curAnim ПОСЛЕ move_and_slide()
	if is_on_floor():
		# Если персонаж на земле, но его текущая анимация - прыжок,
		# значит он только что приземлился. Сбрасываем в IDLE/RUN.
		if curAnim == JUMP:
			if direction:
				curAnim = RUN
			else:
				curAnim = IDLE
		# Если персонаж на земле и не прыгает, определяем IDLE или RUN
		elif curAnim != JUMP: # Добавлено условие, чтобы не менять на RUN/IDLE, если мы уже в JUMP и еще в воздухе
			if direction:
				curAnim = RUN
			else:
				curAnim = IDLE
	# Если персонаж не на земле, и он не нажимал прыжок
	elif not is_on_floor() and curAnim != JUMP:
		curAnim = JUMP


	handle_animations(delta) # Вызов handle_animations после определения curAnim
	
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
		if scale == scale_normal and has_deminishing_gem == true:
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
		if scale == scale_normal and has_magnifying_gem == true:
			start_scale = scale
			target_scale = scale_big
			elapsed_time = 0.0
			animating = true
