class_name CharacterRenderer
extends Node2D

## 角色数据资源（可在 Inspector 中指定，或调用 set_character 动态加载）
@export var character_data: CharacterData

## 允许的最大水平旋转角度（绝对值），防止极端角度穿帮
@export var max_angle: float = 90.0

## 视差强度（全局乘数，每层深度会进一步调制）
@export var parallax_strength: float = 0.002

## 表情混合强度（0=不显示表情，1=完全显示）
@export var expression_strength: float = 0.0

var _sprite: Sprite2D
var _material: ShaderMaterial

func _ready():
	# 创建渲染载体
	_sprite = Sprite2D.new()
	add_child(_sprite)

	# 创建 ShaderMaterial
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/character_blend.gdshader")
	_sprite.material = _material

	# 设置全局 Shader 参数
	_material.set_shader_parameter("parallax_strength", parallax_strength)
	_material.set_shader_parameter("expr_strength", expression_strength)

	# 如果 Inspector 中已经配置了角色，则自动加载
	if character_data:
		set_character(character_data)
	else:
		print("CharacterRenderer: No character_data assigned. Waiting for set_character()...")


## 设置角色数据（外部调用）
func set_character(data: CharacterData) -> void:
	character_data = data
	if not _material:
		return

	if character_data.views.is_empty():
		push_warning("CharacterRenderer: CharacterData has no views.")
		return

	# 当前 Shader 最多支持 2 层（后层 + 前层），取实际层数和 2 的最小值
	var num_layers = mini(character_data.views[0].layers.size(), 2)

	# 清空所有层的纹理槽位（5 个角度）
	for l in range(2):
		for v in range(5):
			_material.set_shader_parameter("layer_%d_tex_%d" % [l, v], null)

	# 遍历每个视图，设置纹理
	for view in character_data.views:
		var view_index = angle_to_index(view.angle)
		if view_index == -1:
			push_warning("CharacterRenderer: Unsupported angle %f. Supported: -90, -45, 0, 45, 90" % view.angle)
			continue

		for l in range(num_layers):
			if l < view.layers.size():
				var layer = view.layers[l]
				_material.set_shader_parameter("layer_%d_tex_%d" % [l, view_index], layer.texture)
				_material.set_shader_parameter("layer_%d_depth" % l, layer.depth)
				_material.set_shader_parameter("layer_%d_anchor" % l, layer.anchor)

	# 使用第一个视图的第一层纹理作为 Sprite2D 的占位纹理，确保正确的 UV 区域
	if character_data.views[0].layers.size() > 0:
		_sprite.texture = character_data.views[0].layers[0].texture
	else:
		push_warning("CharacterRenderer: First view has no layers.")
	# 调试：打印每个视图的映射结果
	# 调试：打印每个视图、每一层的映射和纹理状态
	for view in character_data.views:
		var idx = angle_to_index(view.angle)
		for l in range(view.layers.size()):
			var tex = view.layers[l].texture
			var status = "OK" if tex != null else "NULL!"
			print("View angle=%f -> index=%d, layer=%d, texture=%s [%s]" % [view.angle, idx, l, str(tex), status])

	print("CharacterRenderer: Character loaded with %d view(s), %d layer(s)." % [character_data.views.size(), num_layers])


## 设置当前视角角度（水平旋转）
func set_view_angle(angle: float) -> void:
	if _material:
		angle = clamp(angle, -max_angle, max_angle)
		_material.set_shader_parameter("view_angle", angle)


## 设置视差强度（运行时调整）
func set_parallax_strength(strength: float) -> void:
	parallax_strength = strength
	if _material:
		_material.set_shader_parameter("parallax_strength", strength)


## 设置表情纹理（预留差分接口）
## tex_neg90: -90° 表情纹理
## tex_neg45: -45° 表情纹理
## tex_front: 0° 表情纹理
## tex_pos45: 45° 表情纹理
## tex_pos90: 90° 表情纹理
func set_expression_textures(tex_neg90: Texture2D, tex_neg45: Texture2D, tex_front: Texture2D, tex_pos45: Texture2D, tex_pos90: Texture2D) -> void:
	if not _material:
		return
	_material.set_shader_parameter("expr_tex_0", tex_neg90)
	_material.set_shader_parameter("expr_tex_1", tex_neg45)
	_material.set_shader_parameter("expr_tex_2", tex_front)
	_material.set_shader_parameter("expr_tex_3", tex_pos45)
	_material.set_shader_parameter("expr_tex_4", tex_pos90)


## 设置表情混合强度（0~1）
func set_expression_strength(strength: float) -> void:
	expression_strength = clamp(strength, 0.0, 1.0)
	if _material:
		_material.set_shader_parameter("expr_strength", expression_strength)


## 获取当前表情强度
func get_expression_strength() -> float:
	return expression_strength


## 将角度值映射到纹理索引（0~4），无效角度返回 -1
func angle_to_index(angle: float) -> int:
	if abs(angle - (-90.0)) < 0.1:
		return 0
	elif abs(angle - (-45.0)) < 0.1:
		return 1
	elif abs(angle - 0.0) < 0.1:
		return 2
	elif abs(angle - 45.0) < 0.1:
		return 3
	elif abs(angle - 90.0) < 0.1:
		return 4
	else:
		return -1
