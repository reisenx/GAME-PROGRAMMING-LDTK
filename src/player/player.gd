extends CharacterBody2D

@export var speed = 70.0
@export var jump_velocity = -300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var attack_hitbox = $Area2D

var has_key = false
var is_attacking = false 

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# JUMP
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# ATTACK
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		is_attacking = true
		sprite.play("attack")
		execute_attack() # Check for enemies right as we swing

	# MOVEMENT
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0) 
		
		# Flip the hitbox to match the sprite direction
		if attack_hitbox:
			var default_x_offset = abs(attack_hitbox.position.x)
			if direction < 0:
				attack_hitbox.position.x = -default_x_offset # Move left
			else:
				attack_hitbox.position.x = default_x_offset  # Move right
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	# ANIMATIONS
	if not is_attacking:
		update_animations(direction)

func execute_attack():
	# If the hitbox exists, find everything currently inside it
	if attack_hitbox:
		var bodies_in_range = attack_hitbox.get_overlapping_bodies()
		for body in bodies_in_range:
			# If the body we hit has a 'die' function (like our enemy), call it!
			if body.has_method("die"):
				body.die()

func update_animations(direction):
	if not is_on_floor():
		sprite.play("jump")
	else:
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false

func collect_key(key_name):
	has_key = true
	print("Player now has: ", key_name)

func take_damage():
	print("Player took a hit! (Flickering red, but immortal)")
	
	# Create a Tween to handle the flicker animation
	var tween = create_tween()
	
	# Tell the tween to repeat the sequence 3 times
	tween.set_loops(3)
	
	# Step 1: Tint the sprite RED instantly (over 0.1 seconds)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	
	# Step 2: Tint the sprite back to WHITE (normal) over 0.1 seconds
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
