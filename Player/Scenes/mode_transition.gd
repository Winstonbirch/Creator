# ===========================
# ModeTransition.gd - Handles pixelated transition between modes
# ===========================
extends CanvasLayer

signal transition_finished

@export var transition_duration: float = 0.8
@export var pixel_size_max: int = 64

var is_transitioning: bool = false
var transition_timer: float = 0.0
var transitioning_to_mode = null

var color_rect: ColorRect
var shader_material: ShaderMaterial

func _ready():
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	_setup_pixelation_shader()
	
	color_rect.modulate.a = 0.0
	visible = false

func _setup_pixelation_shader():
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 128.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixelated_uv = floor(SCREEN_UV * screen_size / pixel_size) * pixel_size / screen_size;
	COLOR = texture(screen_texture, pixelated_uv);
}
"""
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	color_rect.material = shader_material

func _process(delta):
	if not is_transitioning:
		return
	
	transition_timer += delta
	var progress = transition_timer / transition_duration
	
	if progress < 0.5:
		_update_transition_in(progress * 2.0)
	else:
		_update_transition_out((progress - 0.5) * 2.0)
	
	if progress >= 1.0:
		_finish_transition()

func _update_transition_in(progress: float):
	visible = true
	var pixel_size = lerp(1.0, float(pixel_size_max), progress)
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	color_rect.modulate.a = progress

func _update_transition_out(progress: float):
	var pixel_size = lerp(float(pixel_size_max), 1.0, progress)
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	color_rect.modulate.a = 1.0 - progress

func _finish_transition():
	is_transitioning = false
	visible = false
	color_rect.modulate.a = 0.0
	transition_finished.emit()

func start_transition(to_mode):
	if is_transitioning:
		return
	
	transitioning_to_mode = to_mode
	is_transitioning = true
	transition_timer = 0.0
	
	return transition_duration * 0.5
