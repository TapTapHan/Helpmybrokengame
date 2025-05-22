1  extends YourNodeTypeName # e.g., extends CharacterBody3D, Node3D, or RigidBody3D
 2
 3  # --- Corrected @onready variable declarations ---
 4
 5  # Muzzle Flash (CPUParticles3D - assuming this is the primary one you want)
 6  @onready var muzzle_flash_cpu: CPUParticles3D = $MuzzlePoint/MuzzleFlashParticles
 7
 8  # If you had a second muzzle flash (GPUParticles3D) that you want to use,
 9  # you need to give it a different variable name and its correct path.
10  # UNCOMMENT THE NEXT LINE AND ADJUST PATH IF NEEDED:
11  # @onready var muzzle_flash_gpu: GPUParticles3D = $Camera3D/pistol/GPUParticles3D
12  # (Make sure the path "$Camera3D/pistol/GPUParticles3D" is correct in your scene tree)
13
14
15 # Your Camera3D reference (renamed for clarity)
16  @onready var main_camera: Camera3D = $Camera3D
17
18 # Your AnimationPlayer reference (renamed for clarity)
19  @onready var gun_animation_player: AnimationPlayer = $AnimationPlayer
20
21 # Your RayCast3D reference (renamed for clarity)
22  @onready var gun_raycast: RayCast3D = $Camera3D/RayCast3D
23
24 # Your AudioStreamPlayer3D for the gunshot sound (renamed for clarity)
25  @onready var gunshot_sound: AudioStreamPlayer3D = %GunshotSound # % is for autoloads/global scenes
26
27
28 # --- Your other export variables (these were already correct) ---
29  @export var health : int = 2
30  @export var spawns : PackedVector3Array = [
31      Vector3(-10, 0, 2),
32      Vector3(10, 0, 2),
33      Vector3(0, 0, 0)
34  ]
35
36 # --- (Add your other functions below this, like _process, fire_gun, etc.) ---
[5:55 PM]
extends YourNodeTypeName # e.g., extends CharacterBody3D, Node3D, or RigidBody3D

	if Input.is_action_just_pressed("capture"):
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity -= ProjectSettings.get_setting(physics/3d/default_gravity) * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor() :
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

@rpc("call_local")
func play_shoot_effects() -> void:
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func recieve_damage(damage:= 1) -> void:
	health -= damage
	if health <= 0:
		health = 2
		position = spawns[randi() % spawns.size()]

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		anim_player.play("idle")
