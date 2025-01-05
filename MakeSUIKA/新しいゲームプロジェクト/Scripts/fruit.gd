extends RigidBody2D

enum FruitType {
    CHERRY = 1,
    STRAWBERRY = 2,
    GRAPE = 3,
    ORANGE = 4,
    APPLE = 5,
    PEAR = 6,
    PEACH = 7,
    PINEAPPLE = 8,
    MELON = 9,
    WATERMELON = 10
}

const FRUIT_TYPES_TO_SPAWN = [
    FruitType.CHERRY,
    FruitType.STRAWBERRY,
    FruitType.GRAPE,
    FruitType.ORANGE
]

var fruit_type = FRUIT_TYPES_TO_SPAWN.pick_random() 
var is_merging = false
var marked_for_deletion = false # 削除マークを追加

func _ready():
    linear_damp = 0 # 追加
    contact_monitor = true
    max_contacts_reported = 4
    body_entered.connect(_on_body_entered)

    gravity_scale = 1.0
    mass = 1.0

    var physics_material = PhysicsMaterial.new()
    physics_material.bounce = 0.2
    physics_material_override = physics_material

    collision_layer = 1
    collision_mask = 1

    setup_fruit_appearance()
    print("Fruit.gd _ready(): fruit_type=", fruit_type, " position=", position, " global_position=", global_position)
    
func _physics_process(delta):
    print("Fruit.gd _physics_process(): position=", position, ", global_position=", global_position, ", linear_velocity=", linear_velocity)

func setup_fruit_appearance():
    
    var sprite = $Sprite2D
    var collision_shape = $CollisionShape2D

    var texture_path = "res://Assets/fruits/%s.png" % FruitType.keys()[fruit_type].to_lower()
    sprite.texture = load(texture_path)

    var scales = {
        FruitType.CHERRY: Vector2(0.1, 0.1),
        FruitType.STRAWBERRY: Vector2(0.15, 0.15),
        FruitType.GRAPE: Vector2(0.18, 0.18),
        FruitType.ORANGE: Vector2(0.2, 0.2),
        FruitType.APPLE: Vector2(0.3, 0.3),
        FruitType.PEAR: Vector2(0.35, 0.35),
        FruitType.PEACH: Vector2(0.4, 0.4),
        FruitType.PINEAPPLE: Vector2(0.5, 0.5),
        FruitType.MELON: Vector2(0.65, 0.65),
        FruitType.WATERMELON: Vector2(0.7, 0.7)
    }
    sprite.scale = scales[fruit_type]

    var sizes = {
        FruitType.CHERRY: 20 * scales[FruitType.CHERRY].x,
        FruitType.STRAWBERRY: 20 * scales[FruitType.STRAWBERRY].x,
        FruitType.GRAPE: 20 * scales[FruitType.GRAPE].x,
        FruitType.ORANGE: 20 * scales[FruitType.ORANGE].x,
        FruitType.APPLE: 400 * scales[FruitType.APPLE].x,
        FruitType.PEAR: 400 * scales[FruitType.PEAR].x,
        FruitType.PEACH: 400 * scales[FruitType.PEACH].x,
        FruitType.PINEAPPLE: 400 * scales[FruitType.PINEAPPLE].x,
        FruitType.MELON: 400 * scales[FruitType.MELON].x,
        FruitType.WATERMELON: 400 * scales[FruitType.WATERMELON].x
    }

    var circle_shape = CircleShape2D.new()
    circle_shape.radius = sizes[fruit_type] / 2
    collision_shape.shape = circle_shape
    print("Fruit.gd setup_fruit_appearance(): fruit_type=", fruit_type)

func _on_body_entered(body):
    print("Fruit.gd _on_body_entered(): This fruit_type=", fruit_type, ", Other body=", body, ", Other body name=", body.name)
    if (body is RigidBody2D or body is StaticBody2D) and not is_merging and not marked_for_deletion: # 条件を変更
        if body is RigidBody2D:
            print("body is RigidBody")
        else:
            print("body is StaticBody")

        print("============ Collision Debug ============")
        print("Before collision check:")
        print("- This fruit position: ", position)
        print("- This fruit type: ", fruit_type)
        if body is RigidBody2D:
            print("- Other fruit position: ", body.position)
            print("- Other fruit type: ", body.fruit_type)
        
        # bodyがStaticBody2Dの時は、bodyにマージ対象のフルーツのプロパティが存在しないため、以下の処理は、bodyがRigidBody2Dの時のみ実行する
        if body is RigidBody2D and body.fruit_type == fruit_type and fruit_type < FruitType.WATERMELON:
            print("Collision check passed")
            print("Creating new fruit with type: ", fruit_type + 1)

            is_merging = true
            body.is_merging = true

            # 削除マークをつける
            marked_for_deletion = true
            body.marked_for_deletion = true

            var merge_position = (position + body.position) / 2
            print("merge_position calculated:", merge_position)
            call_deferred("merge_fruits", body, merge_position)
        else:
            print("Collision check failed: Different fruit types or already WATERMELON")
    else:
        print("Collision check failed: Conditions not met")

func merge_fruits(body, merge_position):
    print("Fruit.gd merge_fruits(): merge_position=", merge_position)
    if not is_instance_valid(body) or not is_instance_valid(self):
        print("merge_fruits: Invalid body or self")
        return

    var next_fruit = load("res://Fruit.tscn").instantiate()
    next_fruit.fruit_type = fruit_type + 1
    next_fruit.position = merge_position
    
    # 新しいフルーツの見た目を設定
    next_fruit.setup_fruit_appearance()
    
    get_parent().add_child(next_fruit)
    print("New fruit created at position:", merge_position, " with type:", next_fruit.fruit_type)

    is_merging = false
    if is_instance_valid(body):
        body.is_merging = false

    print("Deleting fruits: self=", self, " body=", body)
    body.queue_free()
    queue_free()


func _integrate_forces(_state):
    #print("Fruit.gd _integrate_forces(): global_position=", global_position)
    if global_position.y > 1000:
        print("Fruit.gd _integrate_forces(): Fruit reached y > 1000, global_position=", global_position)
        if global_position.y > 1200:
            print("Fruit.gd _integrate_forces(): Fruit reached y > 1200, changing scene to GameOver")
            get_tree().change_scene_to_file("res://GameOver.tscn")
            return

        print("Fruit.gd _integrate_forces(): Freezing fruit, global_position=", global_position)
        linear_velocity = Vector2.ZERO
        angular_velocity = 0
        freeze = true
