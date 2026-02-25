extends Node2D


var clicks: PackedVector2Array = []
var thread_clicks: PackedVector2Array = []


func _draw() -> void:
	for click: Vector2 in clicks:
		draw_circle(click, 8.0, Color.RED)
	for click: Vector2 in thread_clicks:
		draw_circle(click, 8.0, Color.BLUE, false, 4.0)


func _on_window_paint_debug_click(pos: Vector2) -> void:
	clicks.append(pos)
	queue_redraw()


func _on_window_paint_debug_thread_click(pos: Vector2) -> void:
	thread_clicks.append(pos)
	queue_redraw()


func _on_window_paint_debug_clear() -> void:
	clicks = []
	thread_clicks = []
	queue_redraw()
