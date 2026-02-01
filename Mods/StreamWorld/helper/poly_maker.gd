extends TextureRect


@onready var polygon_2d: Polygon2D = $Polygon2D


func _ready() -> void:
	print(polygon_2d.polygon)
