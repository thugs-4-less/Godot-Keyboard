extends Control

# UI References - Get all necessary UI components
@onready var typed_text: Label = $Screen/Background/AllComponentsComtainer/DisplayContainer/MarginContainer/TypedText
@onready var all_buttons: VBoxContainer = $Screen/Background/AllComponentsComtainer/AllButtons
@onready var button_rows: VBoxContainer = $Screen/Background/AllComponentsComtainer/AllButtons/ButtonRows
@onready var line_len = 0  # Track current line length for word wrapping
@onready var cpl: Button = $Screen/Background/AllComponentsComtainer/AllButtons/ButtonRows/Row3/CPL  # Caps lock button

# Keyboard Layout Definitions
# Standard QWERTY layout with special keys
var keyboard_layout := [
	["q","w","e","r","t","y","u","i","o","p"],
	["a","s","d","f","g","h","j","k","l"],
	["⬆","z","x","c","v","b","n","m","⌫"],  # ⬆ = caps, ⌫ = backspace
	["123","⚙️","🙂","space",".","↵"]        # 123 = numbers, ⚙️ = settings, 🙂 = emoji, ↵ = enter
]

# Numbers and symbols layout
var symbols_layout := [
	["1","2","3","4","5","6","7","8","9","0"],
	["@","#","$","_","&","-","+","(",")","/"],
	["*","\"","'",";",":","!","?","=","⌫"],  # Made 9 elements to match keyboard_layout structure
	["ABC","⚙️",",","space",".","↵"]         # ABC = back to letters
]

# State Variables
var has_been_used := false    # Track if any text has been entered
var letter : String          # Unused variable (legacy)
var caps_on = false          # Track caps lock state
var symbols_on = false       # Track if in symbols mode or letters mode

# Cursor System Variables
var cursor_visible := true   # Control cursor blink state
var cursor_timer: Timer      # Timer for cursor blinking
var actual_text := ""        # Store the real text content (without cursor)

func _ready() -> void:
	# Connect all letter and number buttons to the input handler
	for row in button_rows.get_children():
		if row is HBoxContainer:
			for button in row.get_children():
				if button is BaseButton:
					var n := String(button.name)
					# Only connect buttons with single letter names or "dot"
					if n in "abcdefghijklmnopqrstuvwxyz" or n == "dot":
						button.pressed.connect(Callable(self, "_letter_numbers").bind(button))

	# Set up blinking cursor system
	cursor_timer = Timer.new()
	cursor_timer.wait_time = 0.5  # Blink every half second
	cursor_timer.timeout.connect(_on_cursor_blink)
	add_child(cursor_timer)
	cursor_timer.start()
	update_display()  # Initial display update

# Cursor System Functions
func _on_cursor_blink():
	"""Toggle cursor visibility for blinking effect"""
	cursor_visible = !cursor_visible
	update_display()

func update_display():
	"""Update the displayed text with or without cursor"""
	if cursor_visible and has_been_used:
		typed_text.text = actual_text + "|"  # Show cursor
	else:
		typed_text.text = actual_text        # Hide cursor

# Text Input Functions
func _letter_numbers(button):
	"""Handle input from letter, number, and symbol buttons"""
	if not has_been_used:
		# First character typed
		actual_text = button.text
		has_been_used = true
		line_len = 1
	else:
		# Check if adding this character would exceed the line limit (52 chars)
		if line_len >= 52:
			actual_text += "\n"  # Add newline for word wrap
			line_len = 0
		
		actual_text += button.text
		line_len += 1
	update_display()

func _on_space_pressed() -> void:
	"""Handle space bar input"""
	if not has_been_used:
		# First character is a space
		actual_text = " "
		has_been_used = true
		line_len = 1
	else:
		# Check line length before adding space
		if line_len >= 52:
			actual_text += "\n"
			line_len = 0
		
		actual_text += " "
		line_len += 1
	update_display()

func _on_del_pressed() -> void:
	"""Handle backspace/delete functionality"""
	if actual_text.is_empty():
		# Nothing to delete
		has_been_used = false
		line_len = 0
		update_display()
		return

	# Remove last character safely
	actual_text = actual_text.substr(0, actual_text.length() - 1)
	has_been_used = actual_text.length() > 0

	# Recompute current line length after deletion
	var last_nl := actual_text.rfind("\n")  # Find last newline
	if last_nl == -1:
		# No newlines, line length is total text length
		line_len = actual_text.length()
	else:
		# Line length is characters after last newline
		line_len = actual_text.length() - last_nl - 1
	update_display()

func _on_enter_pressed() -> void:
	"""Handle enter/return key - add newline"""
	actual_text += "\n"
	has_been_used = true
	line_len = 0  # Reset line length counter
	update_display()

# Layout Control Functions
func _on_cpl_pressed() -> void:
	"""Handle caps lock button press"""
	# Only toggle caps when in letter mode (not symbols)
	if not caps_on && not symbols_on:
		# Turn caps ON - convert all button text to uppercase
		for row in button_rows.get_children():
			if row is HBoxContainer:
				for button in row.get_children():
					if button is BaseButton:
						button.text = button.text.to_upper()
						caps_on = true
	else:
		# Turn caps OFF - convert all button text to lowercase
		for row in button_rows.get_children():
			if row is HBoxContainer:
				for button in row.get_children():
					if button is BaseButton:
						button.text = button.text.to_lower()
						caps_on = false
	
	# Update caps lock button appearance
	if caps_on:
		cpl.text = "⬇"  # Down arrow when caps is on
	else:
		if not symbols_on:
			cpl.text = "⬆"  # Up arrow when caps is off and in letter mode
	
	# Special behavior: when in symbols mode, caps button types "*"
	if symbols_on:
		if not has_been_used:
			actual_text = "*"
			has_been_used = true
		else:
			actual_text += "*"
		update_display()

func _on__pressed() -> void:
	"""Handle 123/ABC button - switch between letters and symbols layouts"""
	var i := 0
	if not symbols_on:
		# Switch TO symbols mode
		for row in button_rows.get_children():
			var j := 0
			if row is HBoxContainer:
				for button in row.get_children():
					if button is BaseButton:
						button.text = symbols_layout[i][j]  # Apply symbols layout
						j += 1
				i += 1
		symbols_on = true
	else:
		# Switch BACK to letters mode
		for row in button_rows.get_children():
			var j := 0
			if row is HBoxContainer:
				for button in row.get_children():
					if button is BaseButton:
						button.text = keyboard_layout[i][j]  # Apply keyboard layout
						j += 1
				i += 1
		symbols_on = false

func _on_emoji_pressed() -> void:
	"""Handle emoji button press - types comma when in symbols mode"""
	if symbols_on and not has_been_used:
		# First character is comma
		actual_text = ","
		has_been_used = true
	elif symbols_on and has_been_used:
		actual_text += ","
	update_display()
