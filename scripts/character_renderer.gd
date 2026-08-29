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
var _placeholder_tex: Texture2D

func _ready():
	# 创建渲染载体
	_sprite = Sprite2D.new()
	add_child(_sprite)

	# 创建 ShaderMaterial
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/character_blend.gdshader")
	_sprite.material = _material

	# 创建并缓存透明占位纹理，防止 shader 采样到未赋值的 sampler 导致调试色
	_placeholder_tex = _create_placeholder_texture()

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
	var num_layers = min(character_data.views[0].layers.size(), 2)

	# 清空所有层的纹理槽位（5 个角度），先填充为透明占位纹理，避免 shader 出现调试颜色
	for l in range(2):
		for v in range(5):
			_material.set_shader_parameter("layer_%d_tex_%d" % [l, v], _placeholder_tex)

	# 为每一层设置 depth / anchor（如果有），并把每个视图的纹理填进去
	for view in character_data.views:
		var view_index = angle_to_index(view.angle)
		if view_index == -1:
			push_warning("CharacterRenderer: Unsupported angle %f. Supported: -90, -45, 0, 45, 90" % view.angle)
			continue

		for l in range(num_layers):
			if l < view.layers.size():
				var layer = view.layers[l]
				# 只要有 layer 对象就设置对应 slot（覆盖占位纹理）
				_material.set_shader_parameter("layer_%d_tex_%d" % [l, view_index], layer.texture if layer.texture != null else _placeholder_tex)
				# depth / anchor 对每层而言是全局的——以最后一次设置为准（通常每层在所有 view 中 depth 相同）
				_material.set_shader_parameter("layer_%d_depth" % l, layer.depth)
				_material.set_shader_parameter("layer_%d_anchor" % l, layer.anchor)

	# 使用第一个视图的第一层纹理作为 Sprite2D 的占位纹理，确保正确的 UV 区域
	if character_data.views[0].layers.size() > 0 and character_data.views[0].layers[0].texture != null:
		_sprite.texture = character_data.views[0].layers[0].texture
	else:
		# 如果没有任何纹理可用，使用透明占位纹理
		_sprite.texture = _placeholder_tex
		push_warning("CharacterRenderer: First view has no layers or texture; using transparent placeholder.")

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
	# 允许少量浮点容差
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


## 生成一个透明 1x1 的占位纹理，避免 shader 采样未绑定的 sampler 时出现调试色
func _create_placeholder_texture() -> Texture2D:
	var img = Image.new()
	# 创建 RGBA8 格式的 1x1 图像
	img.create(1, 1, false, Image.FORMAT_RGBA8)
	img.lock()
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	img.unlock()
	var tex = ImageTexture.create_from_image(img)
	return tex
