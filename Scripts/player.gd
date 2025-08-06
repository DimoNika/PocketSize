extends CharacterBody3D

# ===== БАЗОВЫЕ ЗНАЧЕНИЯ =====
const SPEED = 12
const JUMP_VELOCITY = 18
const GRAVITY = 40
const DOWN_GRAVITY_FACTOR = 1.2
const acc = 0.5
const friction = 70

var jumping = false # для модификатора гравитации
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer

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



# ===== АНИМАЦИЯ =====
@export var blend_speed = 15

enum { IDLE, RUN, JUMP }
var curAnim = IDLE

var head_axis = 0

var run_val = 0
var jump_val = 0
var move_dir = Vector2(velocity.x, velocity.z)



# ===== ЗОНЫ =====
# status if player can mine final wall
signal player_mined
var is_in_minable_area = false
# status if player can't get bigger
var is_in_small_area = false



# ===== СМЕНА СКИНА =====
@onready var anim_tree : AnimationTree = $Gnome/AnimationTree 
@onready var armature = $Gnome/Armature
@onready var light = $Gnome/SpotLight3D

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



# used in worldCamera.gd as offset of camera of defaul posotion
var camera_offset = 0
var move_right = null

# <><><><><><><><><><><><><><><><><><><><><><>

# ===== ГЕМЫ =====
func pick_deminishing_gem(): # [ГЕМ]
	has_deminishing_gem = true
func pick_magnifying_gem(): # [ГЕМ]
	has_magnifying_gem = true



# ===== АНИМАЦИЯ =====
func handle_animations(delta): # [АНИМ]
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

func update_tree(): # [АНИМ]
	anim_tree["parameters/Run/blend_amount"] = run_val
	anim_tree["parameters/Jump/blend_amount"] = jump_val



# ===== СКИН =====
func swap_gnome_model(size_type: String): # [СКИН]
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

func apply_size_change(new_size: Vector3, size_type: String): # [СКИН]
	start_scale = scale
	target_scale = new_size
	elapsed_time = 0.0
	animating = true
	
	swap_gnome_model(size_type)

func update_model_references(): # [СКИН]
	if current_model_node:
		# Ищем AnimationTree в новой модели
		var new_anim_tree = current_model_node.get_node_or_null("AnimationTree")
		anim_tree = new_anim_tree
		
		# Ищем Armature в новой модели
		var new_armature = current_model_node.get_node_or_null("Armature")
		armature = new_armature
		
		# ⚠️ Ищем SpotLight3D в новой модели
		var new_light = current_model_node.get_node_or_null("SpotLight3D")
		light = new_light



func die():
	self.position = Vector3(0, 2, 0)
func _ready():
	# Инициализируем модель при старте
	current_model_node = $Gnome
	update_model_references()
	
	current_size = "normal"
	target_scale = scale_normal
	scale = scale_normal



# !!!!
func _physics_process(delta: float) -> void:
	handle_animations(delta)
	
	# ===== ГРАВИТАЦИЯ =====
	if not is_on_floor():
		if jumping == true:
			#print ("jump")
			velocity.y -= GRAVITY * delta
			if velocity.y < 0:
				jumping = false
		else:
			#print ("fall")
			velocity.y -= GRAVITY * DOWN_GRAVITY_FACTOR * delta
	
	# ===== ПРЫЖОК =====
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer.start() # буфер прыжка
	elif not is_on_floor() and curAnim != JUMP:
		coyote_timer.start() # коёти тайм
		curAnim = JUMP
	
	# Коёти тайм и буфер прыжка
	if (is_on_floor() || coyote_timer.time_left > 0) and jump_buffer_timer.time_left > 0: 
		velocity.y = JUMP_VELOCITY 
		curAnim = JUMP
		jumping = true
		jump_buffer_timer.stop()
		coyote_timer.stop()
	
	# ===== ПОЛУЧЕНИЕ КНОПОК =====
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_left", "ui_right")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# ===== СКОРОСТЬ =====
	if direction:
		velocity.x = move_toward(velocity.x, SPEED * direction.x, acc) 
		light.position = Vector3(light.position.x, light.position.y, 1.25 * direction.x)
		if velocity.x > 0:
			move_right = true
		else:
			move_right = false
	else:
		velocity.x = move_toward(velocity.x, 0, acc)
	
	# ===== КАМЕРА ПЕРЕД ИГРОКОМ =====
	if move_right == true and camera_offset < 1:
		camera_offset += 0.02
	elif move_right == false and camera_offset > -1:
		camera_offset -= 0.02
	
	move_and_slide() # Перемещаем и обновляем is_on_floor()
	
	
	
	# ===== MINE =====
	if Input.is_action_just_pressed("Mine"):
		if is_in_minable_area:
			if current_size == "big":
				anim_tree.set("parameters/Mine/blend_amount", 1)
				await get_tree().create_timer(1.88).timeout
				anim_tree.set("parameters/Mine/blend_amount", 0)
	
	
	
	# ===== ПОВОРОТ АНИМАЦИИ =====
	if direction.length() > 0.1:
		# Вычисляем угол поворота в плоскости XZ
		var look_direction = Vector2(direction.x, direction.y)
		var target_angle = look_direction.angle()

		armature.rotation.y = lerp_angle(armature.rotation.y, target_angle, 15 * delta)
		light.rotation.y = armature.rotation.y + deg_to_rad(180)
	
	
	
	if is_on_floor():
		# Если персонаж на земле, но его текущая анимация - прыжок,
		# значит он только что приземлился. Сбрасываем в IDLE/RUN.
		if curAnim == JUMP or curAnim != JUMP:
			if direction:
				curAnim = RUN
			else:
				curAnim = IDLE
	
	
	
	# ===== АНИМАЦИЯ УМЕНЬШЕНИЯ/УВЕЛИЧЕНИЯ =====
	if animating:
		elapsed_time += delta
		var t = clamp(elapsed_time / duration, 0, 1)
		scale = start_scale.lerp(target_scale, t)
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



	# ===== ЗОНА КОПАНИЯ =====
func _on_mine_box_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = true
	
func _on_mine_box_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = false

	# ===== ЗОНА УМЕНЬШЕНИЯ =====
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		is_in_small_area = true
	pass # Replace with function body.
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		is_in_small_area = false
	pass # Replace with function body.
