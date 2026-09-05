class_name RagdollCharacter
extends Node3D
## "Skinny Guy" physics-based character (ragdoll) for Cranial Nerve Crisis.
## Features realistic joints, player push/manipulation, stress accumulation,
## and state persistence across level transitions.

signal stress_generated(amount: float)
signal ragdoll_manipulated(force: Vector3, position: Vector3)

## Scale factor to convert physical forces/velocities into stress points.
@export var stress_sensitivity: float = 0.05
## Impulse force applied when player pushes a limb/body part.
@export var push_force_multiplier: float = 10.0
## Maximum stress allowed per physics tick to prevent unexpected spikes.
@export var max_stress_per_tick: float = 5.0
## Dampening factor applied to restore default pose or damp joint movements.
@export var pose_dampening: float = 0.1

var _body_parts: Array[RigidBody3D] = []
var _previous_velocities: Array[Vector3] = []
var _body_parts_by_name: Dictionary = {}
var _is_frozen: bool = false

## Limbs & Body segments
@onready var torso: RigidBody3D = $Torso
@onready var head: RigidBody3D = $Head
@onready var upper_arm_l: RigidBody3D = $UpperArmL
@onready var lower_arm_l: RigidBody3D = $LowerArmL
@onready var hand_l: RigidBody3D = $HandL
@onready var upper_arm_r: RigidBody3D = $UpperArmR
@onready var lower_arm_r: RigidBody3D = $LowerArmR
@onready var hand_r: RigidBody3D = $HandR
@onready var upper_leg_l: RigidBody3D = $UpperLegL
@onready var lower_leg_l: RigidBody3D = $LowerLegL
@onready var foot_l: RigidBody3D = $FootL
@onready var upper_leg_r: RigidBody3D = $UpperLegR
@onready var lower_leg_r: RigidBody3D = $LowerLegR
@onready var foot_r: RigidBody3D = $FootR

## Joint constraints
@onready var shoulder_l: Joint3D = $Joints/ShoulderL
@onready var elbow_l: Joint3D = $Joints/ElbowL
@onready var wrist_l: Joint3D = $Joints/WristL
@onready var shoulder_r: Joint3D = $Joints/ShoulderR
@onready var elbow_r: Joint3D = $Joints/ElbowR
@onready var wrist_r: Joint3D = $Joints/WristR
@onready var hip_l: Joint3D = $Joints/HipL
@onready var knee_l: Joint3D = $Joints/KneeL
@onready var ankle_l: Joint3D = $Joints/AnkleL
@onready var hip_r: Joint3D = $Joints/HipR
@onready var knee_r: Joint3D = $Joints/KneeR
@onready var ankle_r: Joint3D = $Joints/AnkleR


func _ready() -> void:
	_collect_body_parts()
	_store_initial_velocities()


func _physics_process(_delta: float) -> void:
	if _is_frozen:
		return
	_calculate_and_apply_stress()


## Collects all RigidBody3D body segments into an array for batch operation.
func _collect_body_parts() -> void:
	_body_parts.clear()
	_body_parts_by_name.clear()
	for child in get_children():
		if child is RigidBody3D:
			_body_parts.append(child)
			_body_parts_by_name[child.name.to_lower()] = child


## Stores initial velocity reference for stress delta computation.
func _store_initial_velocities() -> void:
	_previous_velocities.resize(_body_parts.size())
	for i in range(_body_parts.size()):
		_previous_velocities[i] = _body_parts[i].linear_velocity


## Calculates stress based on angular and linear velocity changes across ragdoll parts.
func _calculate_and_apply_stress() -> void:
	var total_stress_delta: float = 0.0
	var count: int = _body_parts.size()

	if _previous_velocities.size() != count:
		_store_initial_velocities()

	for i in range(count):
		var body: RigidBody3D = _body_parts[i]
		var prev_vel: Vector3 = _previous_velocities[i]
		var current_vel: Vector3 = body.linear_velocity
		var accel: Vector3 = current_vel - prev_vel

		# Stress increases with acceleration magnitude and angular velocity
		var linear_accel_mag: float = accel.length()
		var angular_vel_mag: float = body.angular_velocity.length()

		var body_stress: float = (linear_accel_mag + angular_vel_mag * 0.5) * stress_sensitivity
		total_stress_delta += body_stress

		_previous_velocities[i] = current_vel

	total_stress_delta = minf(total_stress_delta, max_stress_per_tick)

	if total_stress_delta > 0.01:
		if GameState:
			GameState.add_stress(total_stress_delta)
		stress_generated.emit(total_stress_delta)


## Applies impulse to push/manipulate a target limb of the ragdoll.
func push_body_part(
	body_part_name: String,
	force_vector: Vector3,
	local_pos: Vector3 = Vector3.ZERO
) -> void:
	var lower_name: String = body_part_name.to_lower()
	var body: RigidBody3D = _body_parts_by_name.get(lower_name, null) as RigidBody3D

	if not body:
		body = get_node_or_null(body_part_name) as RigidBody3D

	if body and not _is_frozen:
		var impulse: Vector3 = force_vector * push_force_multiplier
		if local_pos == Vector3.ZERO:
			body.apply_central_impulse(impulse)
		else:
			body.apply_impulse(impulse, local_pos)
		ragdoll_manipulated.emit(impulse, body.global_position + local_pos)


## Freezes or unfreezes all ragdoll physical bodies.
func set_frozen(frozen: bool) -> void:
	_is_frozen = frozen
	for body in _body_parts:
		body.freeze = frozen


## Captures full state dictionary of all ragdoll body parts for level transition persistence.
func get_ragdoll_state() -> Dictionary:
	var state: Dictionary = {
		"transform": global_transform,
		"bodies": {}
	}
	for body in _body_parts:
		state["bodies"][body.name] = {
			"transform": body.transform,
			"linear_velocity": body.linear_velocity,
			"angular_velocity": body.angular_velocity
		}
	return state


## Restores full ragdoll state from saved state dictionary.
func load_ragdoll_state(state: Dictionary) -> void:
	if state.has("transform"):
		global_transform = state["transform"]

	if state.has("bodies"):
		var bodies_data: Dictionary = state["bodies"]
		for i in range(_body_parts.size()):
			var body: RigidBody3D = _body_parts[i]
			if bodies_data.has(body.name):
				var b_data: Dictionary = bodies_data[body.name]
				body.transform = b_data.get("transform", body.transform)
				body.linear_velocity = b_data.get("linear_velocity", Vector3.ZERO)
				body.angular_velocity = b_data.get("angular_velocity", Vector3.ZERO)
				if i < _previous_velocities.size():
					_previous_velocities[i] = body.linear_velocity
