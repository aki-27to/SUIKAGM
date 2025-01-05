# Main.gd
extends Node2D
var current_fruit: RigidBody2D
var _score = 0
var score_label
var spawn_delay = 1.0 # フルーツを生成するまでの遅延時間（秒）

# シグナルを定義
signal fruit_merged

func _ready():
	score_label = $Label
		# シグナルを接続
	fruit_merged.connect(add_score) 
	$Timer.wait_time = spawn_delay
	$Timer.one_shot = true
	$Timer.timeout.connect(spawn_fruit)
	spawn_fruit()

func add_score(amount):
	_score += amount
	score_label.text = "Score: %d" % _score

func spawn_fruit():
	if current_fruit == null:
		var fruit_scene = load("res://Fruit.tscn")
		var fruit_instance = fruit_scene.instantiate()
		add_child(fruit_instance)
		
		# 箱の範囲内に制限
		var left_wall = $StaticBody2D/Left
		var right_wall = $StaticBody2D/Right
		var spawn_x = clamp(
			get_viewport_rect().size.x/2,  # デフォルトX座標
			left_wall.position.x + 50,     # 左端 + マージン
			right_wall.position.x - 50     # 右端 - マージン
		)
		
		fruit_instance.position = Vector2(spawn_x, 50)
		fruit_instance.freeze = true
		current_fruit = fruit_instance

func _input(event):
	if current_fruit == null:
		return
		
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if event is InputEventMouseMotion and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		
		# 箱の範囲内に制限
		var left_wall = $StaticBody2D/Left
		var right_wall = $StaticBody2D/Right
		var new_x = clamp(
			event.position.x,
			left_wall.position.x + 40,    # 左端 + マージン
			right_wall.position.x - 40     # 右端 - マージン
		)
		current_fruit.position.x = new_x
		
	if event is InputEventScreenTouch and event.released:
		current_fruit.freeze = false
		current_fruit = null
		$Timer.start()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			current_fruit.freeze = false
			current_fruit = null
			$Timer.start()
