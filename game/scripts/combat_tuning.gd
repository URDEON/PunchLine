extends Resource

@export_group("Autoapuntado")
@export_range(3.0, 35.0, 0.1) var aim_range := 18.0
@export_range(5.0, 85.0, 1.0) var aim_half_angle_degrees := 50.0
@export_range(0.5, 12.0, 0.1) var turn_rate := 5.5
@export_range(0.0, 0.5, 0.01) var camera_influence := 0.18
@export_range(0.0, 0.2, 0.01) var velocity_prediction := 0.08
@export_group("Aproximación y compromiso")
@export_range(0.06, 0.4, 0.01) var projection_windup := 0.12
@export_range(0.4, 2.0, 0.01) var approach_timeout := 1.15
@export_range(4.0, 20.0, 0.1) var initial_speed := 8.0
@export_range(12.0, 40.0, 0.1) var maximum_speed := 22.0
@export_range(4.0, 40.0, 0.1) var acceleration := 18.0
@export_range(1.2, 4.0, 0.1) var commit_distance := 2.5
@export_range(0.08, 0.25, 0.01) var commit_duration := 0.14
@export_range(0.6, 2.0, 0.05) var impact_reach := 1.3
@export_range(0.25, 1.0, 0.05) var impact_radius := 0.6
@export_range(0.1, 0.8, 0.01) var miss_recovery := 0.38
@export_group("Variante cercana")
@export_range(0.8, 3.0, 0.1) var close_activation_range := 2.2
@export_range(0.9, 1.8, 0.05) var orbit_radius := 1.15
@export_range(6.0, 18.0, 0.1) var orbit_speed := 12.0
@export_range(0.08, 0.2, 0.01) var barrage_interval := 0.12
@export_range(0.02, 0.08, 0.005) var strike_anticipation := 0.045
@export_group("Daño")
@export var m1_damage := 5.0
@export var fourth_m1_damage := 8.0
@export var uppercut_damage := 9.0
@export var downslam_damage := 10.0
@export var projection_entry_damage := 4.0
@export var projection_normal_hits := PackedFloat32Array([4.0, 4.0, 6.0])
@export var projection_close_hits := PackedFloat32Array([2.0, 2.0, 2.0, 2.0, 6.0])
@export var counter_damage := 8.0
@export var rush_first_damage := 4.0
@export var rush_follow_damage := 5.0
@export var kick_damage := 12.0
@export var form1_dash_damage := 18.0
@export var form2_dash_damage := 22.0
@export var tendril_entry_damage := 6.0
@export var tendril_throw_damage := 12.0
@export var acceleration_damage := 26.0
@export var domain_tick_damage := 4.0
@export_group("Estados y enfriamientos")
@export var counter_frame_duration := 5.0
@export var projection_cooldown := 11.0
@export var counter_cooldown := 11.0
@export var evolved_dash_cooldown := 7.0
@export var wakeup_protection := 0.35
@export_range(0.01, 0.1, 0.005) var dummy_dodge_delay := 0.04
