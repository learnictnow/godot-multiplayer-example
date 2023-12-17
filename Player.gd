extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		
		$PlayerInput.set_multiplayer_authority(id)

# Player synchronized input.
@onready var player_input = $PlayerInput

@export var player_colour = Color.MAGENTA

func _ready():
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Camera3D.current = true
		$PlayerUI/PlayerID.text = "ID# " + str(player)
		$PlayerUI.visible = true
		
		$Body.get_surface_override_material(0).albedo_color = player_colour
	# Only process on server.
	# EDIT: Left the client simulate player movement too to compesate network latency.
	# set_physics_process(multiplayer.is_server())


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if player_input.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Reset jump state.
	player_input.jumping = false

	# Handle movement.
	var direction = (transform.basis * Vector3(player_input.direction.x, 0, player_input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

