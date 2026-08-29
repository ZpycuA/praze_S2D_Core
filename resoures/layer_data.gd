class_name LayerData
extends Resource

@export var texture: Texture2D
@export var depth: float = 0.0
@export var offset: Vector2 = Vector2.ZERO
@export var anchor: Vector2 = Vector2(0.5, 0.5)  # 纹理中心作为默认锚点
