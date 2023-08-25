extends RigidBody

puppet var position = transform


func _ready():
	set_network_master(1)
	

func _physics_process(delta):
	if Network.local_player_id == 1:
		rset_unreliable("position", transform)
	else:
		transform = position
