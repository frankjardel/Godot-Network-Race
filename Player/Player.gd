extends VehicleBody

const MAX_STEER_ANGLE = 0.35
const STEER_SPEED = 1

const MAX_ENGINE_FORCE = 200
const MAX_BRAKE_FORCE = 10
const MAX_SPEED = 100

var steer_target = 0.0
var steer_angle = 0.0

sync var players = {}
var player_data = {"steer": 0, "engine": 0, "brakes": 0, "position": null}


func _ready():
	players[name] = player_data
	players[name].position = transform

	if not is_local_Player():
		$Camera.queue_free()
	
	
func _physics_process(delta):
	if is_local_Player():
		drive(delta)
	if not Network.local_player_id == 1:
		transform = players[name].position
		
	steering = players[name].steer
	engine_force = players[name].engine
	brake = players[name].brakes
	
	
func is_local_Player():
	return name == str(Network.local_player_id)


func drive(delta):
	var steering_value = apply_steering(delta)
	var throttle = apply_throttle()
	var brakes = apply_brakes()

	update_server(Network.local_player_id, steering_value, throttle, brakes)


func apply_steering(delta):
	var steer_val = 0
	var left = Input.get_action_strength("steer_left")
	var right = Input.get_action_strength("steer_right")
	
	if left:
		steer_val = left
	elif right:
		steer_val = -right
		
	steer_target = steer_val * MAX_STEER_ANGLE
	
	if steer_target < steer_angle:
		steer_angle -= STEER_SPEED * delta
	elif steer_target > steer_angle:
		steer_angle += STEER_SPEED * delta
		
	return steer_angle
	
	
func apply_throttle():
	var throttle_val = 0
	var forward = Input.get_action_strength("forward")
	var back = Input.get_action_strength("back")
	
	if linear_velocity.length() < MAX_SPEED:
		if back:
			throttle_val = -back
		elif forward:
			throttle_val = forward
		
	return throttle_val * MAX_ENGINE_FORCE
	
	
func apply_brakes():
	var brake_val = 0
	var brake_strength = Input.get_action_strength("brake")
	
	if brake_strength:
		brake_val = brake_strength
		
	return brake_val * MAX_BRAKE_FORCE


func update_server(id, steering_value, throttle, brakes):
	if not Network.local_player_id == 1:
		rpc_unreliable_id(1, "manage_clients", id, steering_value, throttle, brakes)
	else:
		manage_clients(id, steering_value, throttle, brakes)
		
	
sync func manage_clients(id, steering_value, throttle, brakes):
	#player_data = {"steer": 0, "engine": 0, "brakes": 0, "position": null}
	players[name].steer = steering_value
	players[name].engine = throttle
	players[name].brakes = brakes
	players[name].position = transform
	rset_unreliable("players", players)
