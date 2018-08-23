extends KinematicBody2D

export(int) var gamepad = 0

# <TWEAKABLE>
const JUMP_HEIGHT = 500.0
const JUMP_DISTANCE = 400.0
const HORIZONTAL_MAX_VELOCITY = 500.0

const ACCELERATION = 2.0 # Accelerating from player input
const DEACCELERATION = 1.5 # Deaccelerating from player input
const DAMPENING = 0.5 # No player input

const IN_AIR_ACCELERATION = ACCELERATION * 0.5
const IN_AIR_DEACCELERATION = DEACCELERATION * 0.5
const IN_AIR_DAMPENING = DAMPENING * 0.5

const POGO_LENGTH = 100.0

const UP = Vector2(0, -1) # Not really supported to change yet. COMING SOON
const SLOPE_STOP_MIN_VELOCITY = 0.01
const MAX_BOUNCES = 4
const FLOOR_MAX_ANGLE = 0.785398

const BALL_RADIUS = 32.0
 # </TWEAKABLE>

const BALL_CIRCUMFERENCE = 2.0 * PI * BALL_RADIUS # NO NEED TO TOUCH!!! BALLS
const DEADZONE = 0.25

enum JUMP{IDLE, PRE, ACTIVE}
const JUMP_DELTA_MARGIN = 0.1
var jump_state = JUMP.IDLE
var jump_delta = 0

var velocity = Vector2()
var angular_velocity = 0
var pogo_direction = Vector2()

var up = Vector2(0, -1)
var gravity
var jump_velocity

var is_on_floor = false
var touching = false

func _ready():
	# MAGIC JUMP STUFF
	jump_velocity = (2 * JUMP_HEIGHT * HORIZONTAL_MAX_VELOCITY) / JUMP_DISTANCE
	gravity = 2 * JUMP_HEIGHT * pow(HORIZONTAL_MAX_VELOCITY, 2) / pow(JUMP_DISTANCE, 2)
	
	$PogoStick.cast_to.x = POGO_LENGTH

func _physics_process(delta):
	# Temporary set of up
	up = (position - $"../Planet".position).normalized()
	var horizon = Vector2(-up.y, up.x)
	var horizon_angle = horizon.angle()
	rotation = horizon_angle
#	var can_jump = false
#	if is_on_floor:
#		can_jump = true
	
	var input_direction = get_input_direction()
	
	# Horizontal velocity
	var h_target = horizon * input_direction.x * HORIZONTAL_MAX_VELOCITY
	
	# ACCELERATION
	var h_acceleration
	
	if input_direction.length_squared() > 0:
		# There is input from player
		if input_direction.dot(velocity) > 0:
			# Accelerating
			if is_on_floor:
				h_acceleration = ACCELERATION
			else:
				h_acceleration = IN_AIR_ACCELERATION
		else:
			# Deaccelerating
			if is_on_floor:
				h_acceleration = DEACCELERATION
			else:
				h_acceleration = IN_AIR_DEACCELERATION
	else:
		# No input, apply dampening
		if is_on_floor:
			h_acceleration = DAMPENING
		else:
			h_acceleration = IN_AIR_DAMPENING
	
	velocity = velocity.linear_interpolate(h_target, min(h_acceleration * delta, 1))
	
	# JUMP
	var pogo_input_direction = get_analog_input(gamepad, 2, 3)
	if pogo_input_direction.length_squared() > 0:
		pogo_direction = -pogo_input_direction
	
	if Input.is_action_just_pressed("jump"):
		animate_pogo_stick()
	
	if jump_state == JUMP.IDLE:
		if Input.is_action_just_pressed("jump"):
			if $PogoStick.is_colliding():
				jump_state = JUMP.ACTIVE
				velocity.x += jump_velocity * pogo_direction.rotated(horizon_angle).normalized().x
				velocity.y = jump_velocity * pogo_direction.rotated(horizon_angle).normalized().y
				$Jump.play()
				print("DID IT!")
			else:
				jump_state = JUMP.PRE
				jump_delta = 0
	
	elif jump_state == JUMP.PRE:
		jump_delta += delta
		
		if $PogoStick.is_colliding():
			if jump_delta <= JUMP_DELTA_MARGIN:
				jump_state = JUMP.ACTIVE
				velocity.x += jump_velocity * pogo_direction.rotated(horizon_angle).normalized().x
				velocity.y = jump_velocity * pogo_direction.rotated(horizon_angle).normalized().y * 1.5
				$Jump.play()
				print("PRE JUMP!!! ", str(jump_delta))
			else:
				jump_state = JUMP.IDLE
	
	elif jump_state == JUMP.ACTIVE and not Input.is_action_pressed("jump"):
		# Player releases jump button. This terminates the jump.
		jump_state = JUMP.IDLE
	
	# APPLY GRAVITY
#	if not is_on_floor:
	var vertical_velocity = velocity.y
	var vertical_acceleration = up * - gravity
#
#	if vertical_velocity < 0 or jump_state != JUMP.ACTIVE:
#		vertical_acceleration = gravity * 2
#	vertical_velocity += vertical_acceleration * delta
	
	
#	if UP.dot(velocity) > 0 or jump_state != JUMP.ACTIVE:
#		# Falling
#		velocity = 
	
#	velocity.y = vertical_velocity
	velocity += vertical_acceleration * delta
	#DEBUG
	$Control/VelocityX.text = str(velocity.x)
	$Control/VelocityY.text = str(velocity.y)
	$Control/AngularVelocity.text = str(angular_velocity)
	
	# MOVING
	velocity = move_and_slide(velocity, UP, SLOPE_STOP_MIN_VELOCITY, MAX_BOUNCES, FLOOR_MAX_ANGLE)
	is_on_floor = is_on_floor()
	
	if get_slide_count() > 0:
		if not touching:
			$Collide.play()
			if velocity.length() > 0.2:
				$Roll.play()
			else:
				$Roll.stop()
		touching = true
		
		var collision = get_slide_collision(get_slide_count() - 1)
		
		if collision.normal.tangent().dot(velocity) > 0:
			angular_velocity = -velocity.length() * delta / BALL_CIRCUMFERENCE
		
		elif collision.normal.tangent().dot(velocity) < 0:
			angular_velocity = velocity.length() * delta / BALL_CIRCUMFERENCE
		
		else:
			angular_velocity = 0
	else:
		touching = false
		$Roll.stop()
	
	$Sprite.rotation += angular_velocity * 2 * PI
	$PogoStick.rotation = (pogo_direction * -1).angle()
	
#	if is_on_floor:
#		can_jump = true

# ANIMATE POGO STICK

func animate_pogo_stick():
	$PogoStick/Tween.stop_all()
	$PogoStick/Tween.interpolate_property($PogoStick/flesh_stick, "scale", Vector2(0.15, 0.15), Vector2(0.05, 0.15), 0.4, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	$PogoStick/Tween.start()
	


# ANALOG INPUT HELPER FUNCS

func get_analog_input(joy, x, y):
	# Thumbstick
	var analog_input = Vector2()

	analog_input.x = Input.get_joy_axis(joy, x)
	analog_input.y = Input.get_joy_axis(joy, y)

	if analog_input.length_squared() < pow(DEADZONE, 2):
		analog_input = Vector2()
	else:
		analog_input = analog_input.normalized() * (min(analog_input.length_squared(), 1) - pow(DEADZONE, 2)) / (1 - pow(DEADZONE, 2))
	 
	return analog_input

func get_input_direction():
	
	# Thumbstick
	var analog_input = get_analog_input(gamepad, 0, 1)
	
	# Keyboard or D-pad
	var digital_input = Vector2()
	if (Input.is_action_pressed("move_left")):
		digital_input.x -= 1
	if (Input.is_action_pressed("move_right")):
		digital_input.x += 1
	if (Input.is_action_pressed("move_up")):
		digital_input.y -= 1
	if (Input.is_action_pressed("move_down")):
		digital_input.y += 1
	digital_input = digital_input.normalized()
	
	
	return analog_input if digital_input == Vector2() else digital_input