extends Control
@onready var typed_text: Label = $Screen/Background/AllComponentsComtainer/DisplayContainer/MarginContainer/TypedText
@onready var all_buttons: VBoxContainer = $Screen/Background/AllComponentsComtainer/AllButtons
@onready var button_rows: VBoxContainer = $Screen/Background/AllComponentsComtainer/AllButtons/ButtonRows
@onready var line_len = 0
var has_been_used := false
var letter : String

func _ready() -> void:
	for row in button_rows.get_children():
		if row is HBoxContainer:
			for button in row.get_children():
				if button is BaseButton:
					var n := String(button.name)
					if n in "abcdefghijklmnopqrstuvwxyz" or n == "dot":
						button.pressed.connect(Callable(self, "_letter_numbers").bind(button))

func _letter_numbers(button):
	if not has_been_used:
		typed_text.text = button.text
		has_been_used = true
		line_len = 1
	else:
		# Check if adding this character would exceed the line limit
		if line_len >= 52:
			typed_text.text += "\n"
			line_len = 0
		
		typed_text.text += button.text
		line_len += 1

func _on_space_pressed() -> void:
	if not has_been_used:
		typed_text.text = " "
		has_been_used = true
		line_len = 1
	else:
		# Check if adding this space would exceed the line limit
		if line_len >= 52:
			typed_text.text += "\n"
			line_len = 0
		
		typed_text.text += " "
		line_len += 1


func _on_del_pressed() -> void:
	var s := typed_text.text
	if s.is_empty():
		has_been_used = false
		line_len = 0
		return

	# remove last character safely
	s = s.substr(0, s.length() - 1)
	typed_text.text = s
	has_been_used = s.length() > 0

	# recompute current line length after deletion
	var last_nl := s.rfind("\n")
	if last_nl == -1:
		line_len = s.length()
	else:
		line_len = s.length() - last_nl - 1


func _on_enter_pressed() -> void:
	typed_text.text += "\n"
	has_been_used = true
	line_len = 0

		
