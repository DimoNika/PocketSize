extends Node3D

var is_in_minable_area = false
var is_broken = false
var timer = 60
var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent().get_node("Player")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Mine"):
		print(player.current_size)
		if is_broken or not is_in_minable_area or not player.current_size == "big":
			return
		print("player mined")
		# Делаем стену невидимой и отключаем коллизию
		
		is_broken = true
		
		
		
		# Удаляем стену через 2 секунды (после завершения эффектов)
		
	if is_broken == true:
		timer -= 1
	if timer < 0:
		visible = false
		$MineBox/CollisionShape3D.disabled = true
		queue_free()

func _on_mine_box_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = true
	


func _on_mine_box_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		is_in_minable_area = false
