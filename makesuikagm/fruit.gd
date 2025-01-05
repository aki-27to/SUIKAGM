extends RigidBody2D

enum FruitType {
    CHERRY = 0,
    STRAWBERRY = 1,
    GRAPE = 2,
    ORANGE = 3,
    APPLE = 4,
    PEAR = 5,
    PEACH = 6,
    PINEAPPLE = 7,
    MELON = 8,
    WATERMELON = 9
}

# フルーツの種類ごとの得点を定義
const FRUIT_SCORES = {
    FruitType.CHERRY: 10,
    FruitType.STRAWBERRY: 20,
    FruitType.GRAPE: 30,
    FruitType.ORANGE: 40,
    FruitType.APPLE: 50,
    FruitType.PEAR: 80,
    FruitType.PEACH: 100,
    FruitType.PINEAPPLE: 120,
    FruitType.MELON: 150,
    FruitType.WATERMELON: 200
}

const FRUIT_TYPES_TO_SPAWN = [
    FruitType.CHERRY,
    FruitType.STRAWBERRY,
    FruitType.GRAPE,
    FruitType.ORANGE,
    FruitType.APPLE
]

var fruit_type = null
var is_merging = false
var marked_for_deletion = false # 削除マークを追加

func _ready():
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
    
    # _ready() では、fruit_type が null の場合のみランダムに設定する
    if fruit_type == null:
        fruit_type = FRUIT_TYPES_TO_SPAWN.pick_random()

    setup_fruit_appearance()
    
    print("Ready - Contact Monitor: ", contact_monitor)
    print("Ready - Max Contacts: ", max_contacts_reported)
    print("Ready - Body Entered Connected: ", body_entered.get_connections().size() > 0)
    print("Ready - Collision Layer: ", collision_layer)
    print("Ready - Collision Mask: ", collision_mask)

func setup_fruit_appearance():
    var sprite = $Sprite2D
    var collision_shape = $CollisionShape2D
   
    # fruit_type が設定されていない場合は処理を中断
    if fruit_type == null:
        return

    # テクスチャの読み込み
    var texture_path = "res://Assets/fruits/%s.png" % FruitType.keys()[fruit_type].to_lower()
    sprite.texture = load(texture_path)

    print("=== Size Debug for " + FruitType.keys()[fruit_type] + " ===")
    print("Original texture size: ", sprite.texture.get_size())

    # スプライトのスケール設定
    var scales = {
        FruitType.CHERRY: Vector2(0.1, 0.1),
        FruitType.STRAWBERRY: Vector2(0.15, 0.15),
        FruitType.GRAPE: Vector2(0.18, 0.18),
        FruitType.ORANGE: Vector2(0.2, 0.2),
        FruitType.APPLE: Vector2(0.25, 0.25),
        FruitType.PEAR: Vector2(0.3, 0.25),
        FruitType.PEACH: Vector2(0.4, 0.4),
        FruitType.PINEAPPLE: Vector2(0.4, 0.4),
        FruitType.MELON: Vector2(0.4, 0.4),
        FruitType.WATERMELON: Vector2(0.4, 0.4)
    }
    sprite.scale = scales[fruit_type]
    print("Scale: ", sprite.scale)

    # 衝突判定のサイズをスプライトの実際の表示サイズに基づいて設定
    var circle_shape = CircleShape2D.new()
    var sprite_size = sprite.texture.get_size() * sprite.scale
    print("Final sprite size: ", sprite_size)

    # フルーツのサイズに応じて衝突判定のスケールを調整
    var collision_scales = {
        FruitType.CHERRY: 0.9,
        FruitType.STRAWBERRY: 0.9,
        FruitType.GRAPE: 0.9,
        FruitType.ORANGE: 0.85,
        FruitType.APPLE: 0.85,
        FruitType.PEAR: 1.0,
        FruitType.PEACH: 0.9,
        FruitType.PINEAPPLE: 0.9,
        FruitType.MELON: 0.9,
        FruitType.WATERMELON: 0.9
    }

    var collision_scale = collision_scales[fruit_type]
    var final_radius = (sprite_size.x + sprite_size.y) / 4 * collision_scale
    print("Collision radius: ", final_radius)

    circle_shape.radius = final_radius
    collision_shape.shape = circle_shape

func _on_body_entered(body):
    if body is RigidBody2D and not is_merging and not body.is_merging and not marked_for_deletion and not body.marked_for_deletion:
        print("============ Collision Debug ============")
        print("Before collision check:")
        print("- This fruit type: ", fruit_type)
        print("- Other fruit type: ", body.fruit_type)

        if body.fruit_type == fruit_type:
            if fruit_type == FruitType.WATERMELON:
                # スイカ同士の場合は、削除マークをつけてから削除
                print("Watermelons collided! Deleting both.")
                marked_for_deletion = true
                body.marked_for_deletion = true
                call_deferred("delete_watermelons", body)
            elif fruit_type < FruitType.WATERMELON:
                # 通常のマージ処理
                print("Collision check passed")
                print("Creating new fruit with type: ", fruit_type + 1)

                is_merging = true
                body.is_merging = true

                # 削除マークをつける
                marked_for_deletion = true
                body.marked_for_deletion = true

                var merge_position = (position + body.position) / 2
                call_deferred("merge_fruits", body, merge_position)

func delete_watermelons(body):
    if is_instance_valid(body):
        body.queue_free()
    queue_free()

func merge_fruits(body, merge_position):
    if not is_instance_valid(body) or not is_instance_valid(self):
        return

    var next_fruit = load("res://Fruit.tscn").instantiate()

    # 最初に fruit_type を設定
    next_fruit.fruit_type = fruit_type + 1
    
    # その後で setup_fruit_appearance を呼び出す
    next_fruit.setup_fruit_appearance()

    # 位置を設定して追加
    next_fruit.position = merge_position
    get_parent().add_child(next_fruit)

    print("New fruit created at position:", merge_position)
    
    # 位置を設定して追加
    next_fruit.position = merge_position
    get_parent().add_child(next_fruit)

    print("New fruit created at position:", merge_position)

    # スコア加算のシグナルを発信
    var score = FRUIT_SCORES[fruit_type]
    get_tree().get_root().get_node("Main").fruit_merged.emit(score)
    #get_tree().get_root().get_node("Main").fruit_merged.emit(10)
    
    is_merging = false
    if is_instance_valid(body):
        body.is_merging = false

    body.queue_free()
    queue_free()

func _integrate_forces(_state):
    if global_position.y > 1000:
        if global_position.y > 1200:
            get_tree().change_scene_to_file("res://GameOver.tscn")
            return

        linear_velocity = Vector2.ZERO
        angular_velocity = 0
        freeze = true
