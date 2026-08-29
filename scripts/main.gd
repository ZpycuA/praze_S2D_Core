extends Node2D

@onready var renderer := $CharacterRenderer
@onready var angle_slider := $CanvasLayer/AngleSlider

var current_angle := 0.0
var expression_on := false

func _ready():
	# 创建并加载演示角色数据
	if not renderer.character_data:
		var data = create_demo_data()
		renderer.set_character(data)
	
	# 初始角度
	renderer.set_view_angle(current_angle)
	angle_slider.value = current_angle
	
	# 连接滑块信号
	angle_slider.value_changed.connect(_on_slider_changed)

func _on_slider_changed(value: float) -> void:
	current_angle = value
	renderer.set_view_angle(current_angle)

func _input(event):
	# 鼠标左键拖动旋转
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		current_angle -= event.relative.x * 0.2
		current_angle = clamp(current_angle, -90.0, 90.0)
		renderer.set_view_angle(current_angle)
		angle_slider.value = current_angle

func _unhandled_input(event):
	# 按 E 键切换闭眼表情
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		expression_on = not expression_on
		renderer.set_expression_strength(1.0 if expression_on else 0.0)
		print("Expression: ", "ON" if expression_on else "OFF")

func create_demo_data() -> CharacterData:
	var data = CharacterData.new()
	data.character_name = "Demo"
	
	# 后层（脸）纹理路径，按角度顺序：-90, -45, 0, 45, 90
	var back_paths = [
		"res://assets/demo_character/back/left.png",
		"res://assets/demo_character/back/quarter_left.png",
		"res://assets/demo_character/back/front.png",
		"res://assets/demo_character/back/quarter_right.png",
		"res://assets/demo_character/back/right.png",
	]
	
	# 前层（前发）纹理路径
	var front_paths = [
		"res://assets/demo_character/front_hair/left.png",
		"res://assets/demo_character/front_hair/quarter_left.png",
		"res://assets/demo_character/front_hair/front.png",
		"res://assets/demo_character/front_hair/quarter_right.png",
		"res://assets/demo_character/front_hair/right.png",
	]
	
	# 表情差分纹理路径（闭眼）
	var expr_paths = [
		"res://assets/demo_character/expressions/eye_closed_left.png",
		"res://assets/demo_character/expressions/eye_closed_quarter_left.png",
		"res://assets/demo_character/expressions/eye_closed_front.png",
		"res://assets/demo_character/expressions/eye_closed_quarter_right.png",
		"res://assets/demo_character/expressions/eye_closed_right.png",
	]
	
	# 五个角度
	var angles = [-90.0, -45.0, 0.0, 45.0, 90.0]
	
	var views: Array[ViewData] = []
	
	for i in range(5):
		var back_layer = LayerData.new()
		back_layer.texture = load(back_paths[i])
		back_layer.depth = 0.2
		back_layer.anchor = Vector2(0.5, 0.5)
		
		var front_layer = LayerData.new()
		front_layer.texture = load(front_paths[i])
		front_layer.depth = 0.8
		front_layer.anchor = Vector2(0.5, 0.5)
		
		var view = ViewData.new()
		view.angle = angles[i]
		var layer_array: Array[LayerData] = [back_layer, front_layer]
		view.layers = layer_array
		views.append(view)
	
	var views_array: Array[ViewData] = views
	data.views = views_array
	
	# 设置表情差分纹理
	var expr_front = load(expr_paths[2])  # 0°
	var expr_q_left = load(expr_paths[1])  # -45°
	var expr_left = load(expr_paths[0])   # -90°
	var expr_q_right = load(expr_paths[3]) # 45°
	var expr_right = load(expr_paths[4])  # 90°
	
	# 把表情纹理传给渲染器
	renderer.set_expression_textures(expr_left, expr_q_left, expr_front, expr_q_right, expr_right)
	
	return data
