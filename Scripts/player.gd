extends CharacterBody3D

#анимация
@export var blend_speed = 15

signal player_mined

enum { IDLE, RUN, JUMP }
var curAnim = IDLE

var head_axis = 0

var run_val = 0
var jump_val = 0
var move_dir = Vector2(velocity.x, velocity.z)

# status if player can mine final wall
var is_in_minable_area = false

# status if player can't get bigger
var is_in_small_area = false

#@onready var camera = get_viewport().get_camera_3d()
@onready var anim_tree : AnimationTree = $Gnome/AnimationTree 
@onready var armature = $Gnome/Armature
@onready var light = $Gnome/SpotLight3D



# смена скина
const normal_model = preload("res://Scene/gnome.tscn")
const small_model = preload("res://Scene/gnome_blue.tscn")
const big_model = preload("res://Scene/gnome_yellow.tscn")
var size_models = {
	"normal": normal_model,
	"small": small_model,
	"big": big_model
}
var current_model_node: Node3D
var current_size: String = "normal"



const SPEED = 8.0
const JUMP_VELOCITY = 8
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

# used in worldCamera.gd as offset of camera of defaul posotion
var camera_offset = 0

var move_right = null

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

# СКИН
func swap_gnome_model(size_type: String):
	if not size_models.has(size_type) or size_models[size_type] == null:
		push_error("Model for size " + size_type + " not found!")
		return
	
	# Сохраняем текущие трансформации
	var current_transform = global_transform if current_model_node == null else current_model_node.global_transform
	
	# Удаляем старую модель
	if current_model_node:
		current_model_node.queue_free()
	
	# Создаем новую модель
	var new_model = size_models[size_type].instantiate()
	add_child(new_model)
	new_model.global_transform = current_transform
	new_model.name = "Gnome"
	
	# Обновляем ссылки
	current_model_node = new_model
	update_model_references()
	
	return new_model

func apply_size_change(new_size: Vector3, size_type: String):
	start_scale = scale
	target_scale = new_size
	elapsed_time = 0.0
	animating = true
	
	swap_gnome_model(size_type)

func update_model_references():
	if current_model_node:
		# Ищем AnimationTree в новой модели
		var new_anim_tree = current_model_node.get_node_or_null("AnimationTree")
		if new_anim_tree:
			anim_tree = new_anim_tree
		else:
			push_error("AnimationTree not found in model!")
		
		# Ищем Armature в новой модели
		var new_armature = current_model_node.get_node_or_null("Armature")
		if new_armature:
			armature = new_armature
		else:
			push_error("Armature not found in model!")
		
		# ⚠️ Ищем SpotLight3D в новой модели
		var new_light = current_model_node.get_node_or_null("SpotLight3D")
		if new_light:
			light = new_light
		else:
			push_error("SpotLight3D not found in model!")
	else:
		push_error("Current model node is null in update_model_references!")

func _ready():
	# Инициализируем модель при старте
	current_model_node = $Gnome
	update_model_references()
	
	current_size = "normal"
	target_scale = scale_normal
	scale = scale_normal

func die():
	self.position = Vector3(0, 2, 0)
	

# !!!!
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
	
	if Input.is_action_just_pressed("Mine"):
		if is_in_minable_area:
#			player mines
			print("test")
			

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_left", "ui_right")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	# Обновление скорости для движения
	if direction:
		velocity.x = direction.x * SPEED
		
		if velocity.x > 0:
			move_right = true
			light.position = Vector3(light.position.x, light.position.y, 0.85)
		else:
			light.position = Vector3(light.position.x, light.position.y, -0.85)
			move_right = false
			light.position = Vector3(light.position.x, light.position.y, -0.85)
		#velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	

	if move_right == true and camera_offset < 1:
		
		camera_offset += 0.02
	elif move_right == false and camera_offset > -1:
		camera_offset -= 0.02
	
	move_and_slide() # Перемещаем и обновляем is_on_floor()

	if direction.length() > 0.1:
		# Вычисляем угол поворота в плоскости XZ
		var look_direction = Vector2(direction.x, direction.y)
		var target_angle = look_direction.angle()
		var target_angle2 = look_direction.angle() + PI

		armature.rotation.y = lerp_angle(armature.rotation.y, target_angle, 15 * delta)
		light.rotation.y = armature.rotation.y + deg_to_rad(180)
		


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
		#current_model_node.scale = start_scale.lerp(target_scale, t)
		#$CollisionShape3D.scale = start_scale.lerp(target_scale, t)
		if t >= 1.0:
			animating = false
	
	if Input.is_action_just_pressed("deminish"):
		if scale == scale_big:
			apply_size_change(scale_normal, "normal")
			current_size = "normal"
		elif scale == scale_normal and has_deminishing_gem:
			apply_size_change(scale_small, "small")
			current_size = "small"
			
			
	if Input.is_action_just_pressed("magnify"):
		if scale == scale_small and is_in_small_area == false:
			apply_size_change(scale_normal, "normal")
			current_size = "normal"
		elif scale == scale_normal and has_magnifying_gem and is_in_small_area == false:
			apply_size_change(scale_big, "big")
			current_size = "big"
			


func _on_mine_box_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = true
	


func _on_mine_box_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = false
	


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		is_in_small_area = true
	pass # Replace with function body.


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		is_in_small_area = false
	pass # Replace with function body.
