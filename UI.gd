extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	clear_log()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func clear_log():
	$Log1.text = ""
	$Log2.text = ""
	$Log3.text = ""


func log_message(message):
	$Log3.text = $Log2.text
	$Log2.text = $Log1.text
	$Log1.text = message


func display_status(message):
	$StatusText.bbcode_text = "[center][color=red]" + message


func clear_status():
	$StatusText.bbcode_text = ""
