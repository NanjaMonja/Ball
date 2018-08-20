extends KinematicBody2D


const GRAVITY = 200
const ROLL_SPEED_MAX = 200
const ROLL_ACC = 30

var velocity = Vector2()

var ball_rot = 0
var ball_acc = PI/400
var ball_dacc = PI/200
var ball_rot_dead_zone = PI/210
var ball_rot_max = PI/14

var ball_aim = Vector2()


var aim_stick_pos = Vector2()
var dead_zone = 0.9
var airborne = false

func get_input():
	
	if Input.is_action_pressed("ui_roll_left"):
		#velocity.x = -WALK_SPEED
		ball_rot -= ball_acc
		
	elif Input.is_action_pressed("ui_roll_right"):
		#velocity.x = WALK_SPEED 
		ball_rot += ball_acc
		
	else:
		if abs(ball_rot) < ball_rot_dead_zone:
			ball_rot = 0
		elif ball_rot > 0:
			ball_rot -= ball_dacc
		else:
			ball_rot += ball_dacc
			
	if ball_rot > ball_rot_max:
		ball_rot = ball_rot_max
	elif ball_rot < -ball_rot_max:
		ball_rot = -ball_rot_max

func _physics_process(delta):
	get_input()
	velocity.y += GRAVITY * delta
	velocity.x += ball_rot * ROLL_ACC
	#if velocity.x > ROLL_SPEED_MAX:
	#	velocity.x = ROLL_SPEED_MAX
	#elif velocity.x < ROLL_SPEED_MAX:
	#	velocity.x = -ROLL_SPEED_MAX
	
	
	
	if airborne and is_on_floor():
		airborne = false

	if is_on_wall():
		print("on wall")

	velocity.y += delta * GRAVITY
	
	move_and_slide(velocity, Vector2(0,-1))

	draw_stuff()


func _input(event):
   # Mouse in viewport coordinates
	
	if event is InputEventJoypadMotion:
		if event.axis == 0: 
			aim_stick_pos.x = event.axis_value
		if event.axis == 1:
			aim_stick_pos.y = event.axis_value
	
	if aim_stick_pos.length() > dead_zone:
		ball_aim = aim_stick_pos.normalized() * 27	
		$Aim.rect_position = ball_aim
		
func draw_stuff():
	$Sprite.rotation += ball_rot
	
func speed_deadzone(speed, max_speed, dz):
	return speed
	
	
		
		
		
	