# Main.gd
extends Node2D

var current_fruit: RigidBody2D
var _score = 0
var score_label
var spawn_delay = 1.0 # フルーツを生成するまでの遅延時間（秒）

func _ready():
	score_label = $Label
	# 既にシーンに配置されているTimerノードを参照する
	$Timer.wait_time = spawn_delay
	$Timer.one_shot = true
	$Timer.timeout.connect(spawn_fruit) # タイマーのタイムアウト時に spawn_fruit を呼び出す

	spawn_fruit()

func add_score(amount):
	_score += amount
	score_label.text = "Score: %d" % _score

func spawn_fruit():
	if current_fruit == null:
		var fruit_scene = load("res://Fruit.tscn")
		var fruit_instance = fruit_scene.instantiate()
		add_child(fruit_instance)
		fruit_instance.position = Vector2(get_viewport_rect().size.x/2, 50)
		fruit_instance.freeze = true
		current_fruit = fruit_instance
	

func _input(event):
	if current_fruit == null:
		return

	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if event is InputEventMouseMotion and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		current_fruit.position.x = event.position.x

	if event is InputEventScreenTouch and event.released:
		current_fruit.freeze = false
		current_fruit = null
		$Timer.start() # タイマースタート

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			current_fruit.freeze = false
			current_fruit = null
			$Timer.start() # タイマースタート
