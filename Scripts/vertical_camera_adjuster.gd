extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = get_parent().get_node("Player")
	
	position = player.position
	#print(player.position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = get_parent().get_node("Player")
	var target_position = player.position
	self.position.x = player.position.x
	
	var speed_factor = 3
	
	var direction = (target_position - self.position)
	var distance = direction.length()
	var speed = distance * speed_factor  # больше расстояние — больше скорость
	if distance > 1:
		speed = 5
	else:
		speed = 2
	#print(distance)
	
	
	var move_vector = direction.normalized() * speed * delta
	
	
	if distance > 0.05:
		self.global_position += move_vector
