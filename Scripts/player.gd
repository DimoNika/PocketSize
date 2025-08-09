extends CharacterBody3D

# ===== БАЗОВЫЕ ЗНАЧЕНИЯ =====
const SPEED = 12
const JUMP_VELOCITY = 16
const GRAVITY = 30
const DOWN_GRAVITY_FACTOR = 1.2
const ACC = 1

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
@onready var anim_tree : AnimationTree = $Gnome/AnimationTree 
@onready var armature = $Gnome/Armature
@onready var light = $Gnome/Light/SpotLight3D


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
@onready var mesh_red: MeshInstance3D = $Gnome/Armature/Skeleton3D/GnomeRed
@onready var mesh_blue: MeshInstance3D = $Gnome/Armature/Skeleton3D/GnomeBlue
@onready var mesh_yellow: MeshInstance3D = $Gnome/Armature/Skeleton3D/GnomeYellow

var light_colors = {
	"normal": Color(1, 1, 1),      # Белый свет
	"small": Color(0.6, 0.8, 1.0),   # Голубой свет
	"big": Color(0.984, 0.859, 0.576)      # Желтый свет
}
var size_models = {
	"normal": mesh_red,
	"small": mesh_blue,
	"big": mesh_yellow
}
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
func set_light_color(color: Color): # [СКИН]
	if light: # смена цвета фонаря
		light.light_color = color
		
		# Для плавного изменения
		var tween = create_tween()
		tween.tween_property(light, "light_color", color, 0.5)
func hide_all_meshes(): # [СКИН]
	if mesh_red: mesh_red.visible = false
	if mesh_blue: mesh_blue.visible = false
	if mesh_yellow: mesh_yellow.visible = false

func set_mesh_visible(size_type: String): # [СКИН]
	hide_all_meshes()
	match size_type:
		"normal":
			if mesh_red: mesh_red.visible = true
		"small":
			if mesh_blue: mesh_blue.visible = true
		"big":
			if mesh_yellow: mesh_yellow.visible = true

func apply_size_change(new_size: Vector3, size_type: String): # [СКИН]
	start_scale = scale
	target_scale = new_size
	elapsed_time = 0.0
	animating = true
	current_size = size_type
	
	if light_colors.has(size_type):
		set_light_color(light_colors[size_type])
	
	# Меняем видимый меш
	set_mesh_visible(size_type)



func die():
	self.position = Vector3(0, 2, 0)
func _ready():
	# Инициализация мешей: скрываем все, потом показываем нужный
	hide_all_meshes()
	set_mesh_visible("normal")  # Показываем нормальный меш (красный)
	
	# Инициализируем ссылки
	anim_tree = $Gnome/AnimationTree 
	armature = $Gnome/Armature
	light = $Gnome/Light/SpotLight3D
	
	current_size = "normal"
	target_scale = scale_normal
	scale = scale_normal


# ===== Прыжок при зажатии =====
func _input(event):
	if event.is_action_released("Jump"):
		if velocity.y > 0.0:
			velocity.y *= 0.5 # если не зажал кнпоку



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
		velocity.x = move_toward(velocity.x, SPEED * direction.x, ACC) 
		if velocity.x > 0:
			move_right = true
		else:
			move_right = false
	else:
		velocity.x = move_toward(velocity.x, 0, ACC)
	
	
	
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
		var look_direction = Vector2(direction.x, direction.y)
		var target_angle = look_direction.angle()

		armature.rotation.y = lerp_angle(armature.rotation.y, target_angle, 15 * delta)
		light.position = Vector3(light.position.x, light.position.y, direction.x)
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
