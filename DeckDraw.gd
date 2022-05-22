extends TextureButton


var icon_size = Vector2(0.2,0.2)
var Decksize = INF
var EnemyDecksize = INF


# Called when the node enters the scene tree for the first time.
func _ready():
#	rect_scale *= icon_size/rect_scale
	pass



func _gui_input(_event):
	if Input.is_action_just_pressed("click_left"):
		if Decksize > 0:
			Decksize = $"../..".drawcard()
			EnemyDecksize = $"../..".drawenemycard()
		if Decksize == 0:
			disabled = true
