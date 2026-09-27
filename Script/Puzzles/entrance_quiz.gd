extends Control
@export var puzzle_id: String = "entrance_quiz"
signal puzzle_solved(puzzle_id)
signal puzzle_closed(puzzle_id)

# --------------------------------------------------
# QUIZ DATA
# --------------------------------------------------
var quizzes = [
	{
		"question": "Refer Question No. 4.",
		"options": [
			"Option C is incorrect",
			"Option D is incorrect",
			"Option B is incorrect",
			"Option A is correct"
		],
		"answer": 1
	},
	{
		"question": "Refer Question No. 1.",
		"options": [
			"Option C is incorrect",
			"Option D is correct",
			"Option B is incorrect",
			"Option A is incorrect"
		],
		"answer": 0
	},
	{
		"question": "Refer Question No. 2.",
		"options": [
			"Option C is correct",
			"Option D is incorrect",
			"Option B is incorrect",
			"Option A is incorrect"
		],
		"answer": 3
	},
	{
		"question": "Refer Question No. 3.",
		"options": [
			"Option C is incorrect",
			"Option B is correct",
			"Option A is incorrect",
			"Option D is incorrect"
		],
		"answer": 2
	}
];



# --------------------------------------------------
# VARIABLES
# --------------------------------------------------

var current_quiz := 0
var selected_option := -1

# Stores player's answers
var player_answers = [-1, -1, -1, -1]


# --------------------------------------------------
# NODE REFERENCES
# --------------------------------------------------

@onready var question_label = $AspectRatioContainer/Panel/QuizContainer/QuePanel/MarginContainer/Que

@onready var option_buttons = [
	$AspectRatioContainer/Panel/QuizContainer/OptionsContainerPanel/VBoxContainer/Option1Panel/HBoxContainer/Button,
	$AspectRatioContainer/Panel/QuizContainer/OptionsContainerPanel/VBoxContainer/Option2Panel/HBoxContainer/Button2,
	$AspectRatioContainer/Panel/QuizContainer/OptionsContainerPanel/VBoxContainer/Option3Panel/HBoxContainer/Button3,
	$AspectRatioContainer/Panel/QuizContainer/OptionsContainerPanel/VBoxContainer/Option4Panel/HBoxContainer/Button4
]

@onready var save_next_button = $AspectRatioContainer/Panel/QuizContainer/SaveNext
@onready var prev_button = $AspectRatioContainer/Panel/QuizContainer/Prev

@onready var status_panels = [
	$AspectRatioContainer/Panel/QuizContainer/StatusOfQue/no1,
	$AspectRatioContainer/Panel/QuizContainer/StatusOfQue/no2,
	$AspectRatioContainer/Panel/QuizContainer/StatusOfQue/no3,
	$AspectRatioContainer/Panel/QuizContainer/StatusOfQue/no4
]

# Status panel styles (current = blue, answered = green, unanswered = gray)
var status_style_gray := StyleBoxTexture.new()
var status_style_blue := StyleBoxTexture.new()
var status_style_green := StyleBoxTexture.new()

@onready var quiz_container = $AspectRatioContainer/Panel/QuizContainer
@onready var result_screen = $AspectRatioContainer/Panel/Panel

@onready var correct_text = $AspectRatioContainer/Panel/Panel/VBoxContainer/CorrectPanel/CorrectText
@onready var incorrect_text = $AspectRatioContainer/Panel/Panel/VBoxContainer/InCorrectPanel/InCorrectText

@onready var retake_submit_button = $AspectRatioContainer/Panel/Panel/VBoxContainer/RetakeButton


# --------------------------------------------------
# START
# --------------------------------------------------

func _ready():
	# Connect option buttons
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_selected.bind(i))
	# Connect navigation buttons
	save_next_button.pressed.connect(_on_save_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	# Connect result screen buttons
	retake_submit_button.pressed.connect(_on_retake_submit_pressed)
	# Start on the quiz, with the result screen hidden
	quiz_container.visible = true
	result_screen.visible = false
	# Set up status panel textures
	setup_status_styles()

	load_saved_progress()

	if not player_answers.has(-1):
		# Every question already has a saved answer: show the result screen
		finish_quiz()
	else:
		# Resume on the saved question
		load_quiz(current_quiz)


# --------------------------------------------------
# SAVE / LOAD PROGRESS
# --------------------------------------------------

func save_progress():
	GameManager.object_changed(puzzle_id, {
		"current_quiz": current_quiz,
		"player_answers": player_answers
	})


func load_saved_progress():
	var state = SaveManager.get_object_state(puzzle_id)
	if state.has("player_answers"):
		# Duplicate so editing player_answers doesn't silently mutate SaveManager's
		# stored data before save_progress() is actually called
		player_answers = (state["player_answers"] as Array).duplicate()
	if state.has("current_quiz"):
		current_quiz = clampi(state["current_quiz"], 0, quizzes.size() - 1)


# --------------------------------------------------
# STATUS PANEL STYLES
# --------------------------------------------------

func setup_status_styles():
	status_style_gray.texture = load("res://Assets/UI/grey.png")
	status_style_blue.texture = load("res://Assets/UI/blue.png")
	status_style_green.texture = load("res://Assets/UI/green.png")
	for style in [status_style_gray, status_style_blue, status_style_green]:
		style.texture_margin_left = 4.0
		style.texture_margin_top = 4.0
		style.texture_margin_right = 4.0
		style.texture_margin_bottom = 4.0


func update_status_panels():
	for i in range(status_panels.size()):
		if i == current_quiz:
			status_panels[i].add_theme_stylebox_override("panel", status_style_blue)
		elif player_answers[i] != -1:
			status_panels[i].add_theme_stylebox_override("panel", status_style_green)
		else:
			status_panels[i].add_theme_stylebox_override("panel", status_style_gray)


# --------------------------------------------------
# LOAD QUIZ
# --------------------------------------------------
func load_quiz(index: int):
	if index < 0 or index >= quizzes.size():
		return
	current_quiz = index
	var quiz = quizzes[current_quiz]
	# Set question
	question_label.text = quiz["question"]
	# Set options
	for i in range(4):
		option_buttons[i].text = quiz["options"][i]

	# Restore previous answer if player already answered
	selected_option = player_answers[current_quiz]

	update_option_visuals()
	update_status_panels()
	# Update buttons
	prev_button.disabled = current_quiz == 0
	update_save_next_button()


# --------------------------------------------------
# OPTION SELECTED
# --------------------------------------------------

func _on_option_selected(index: int):
	selected_option = index
	player_answers[current_quiz] = index
	update_option_visuals()
	update_status_panels()
	update_save_next_button()
	save_progress()


# --------------------------------------------------
# SAVE/NEXT BUTTON STATE
# --------------------------------------------------

func update_save_next_button():
	if current_quiz == quizzes.size() - 1:
		save_next_button.text = "Finish"
		save_next_button.disabled = player_answers.has(-1)
	else:
		save_next_button.text = "Next"
		save_next_button.disabled = false


# --------------------------------------------------
# UPDATE OPTION APPEARANCE
# --------------------------------------------------

func update_option_visuals():
	for i in range(option_buttons.size()):
		if i == selected_option:
			# Selected option
			option_buttons[i].grab_focus()
		else:
			# Normal option
			option_buttons[i].modulate = Color.WHITE

	# No answer selected for this quiz yet, don't show focus on any option
	if selected_option == -1:
		for button in option_buttons:
			if button.has_focus():
				button.release_focus()


# --------------------------------------------------
# SAVE & NEXT
# --------------------------------------------------

func _on_save_next_pressed():
	# Save answer (may be unanswered, i.e. -1)
	player_answers[current_quiz] = selected_option
	# If this is Quiz 4
	if current_quiz == quizzes.size() - 1:
		# Don't allow finishing until every question has been answered
		if player_answers.has(-1):
			print("Please answer all questions before submitting.")
			return
		finish_quiz()
	else:
		# Move to next quiz
		load_quiz(current_quiz + 1)
		save_progress()


# --------------------------------------------------
# PREVIOUS
# --------------------------------------------------

func _on_prev_pressed():
	if current_quiz > 0:
		# Save current answer
		player_answers[current_quiz] = selected_option
		# Go back
		load_quiz(current_quiz - 1)
		save_progress()


# --------------------------------------------------
# FINISH
# --------------------------------------------------
   
func finish_quiz():
	var score := 0
	for i in range(quizzes.size()):
		if player_answers[i] == quizzes[i]["answer"]:
			score += 1
			
	var wrong := quizzes.size() - score
	correct_text.text = "Correct : %d" % score
	incorrect_text.text = "Incorrect : %d" % wrong
	
	# Only allow submitting once every answer is correct
	var all_correct := score == quizzes.size()
	
	if all_correct:
		retake_submit_button.text = "Submit"
		# Apply green stylebox to the button states
		retake_submit_button.add_theme_stylebox_override("normal", status_style_green)
		retake_submit_button.add_theme_stylebox_override("hover", status_style_green)
		retake_submit_button.add_theme_stylebox_override("pressed", status_style_green)
	else:
		retake_submit_button.text = "Retake"
		# Apply gray or blue stylebox to the button states for retrying
		retake_submit_button.add_theme_stylebox_override("normal", status_style_blue)
		retake_submit_button.add_theme_stylebox_override("hover", status_style_blue)
		retake_submit_button.add_theme_stylebox_override("pressed", status_style_blue)
		
	quiz_container.visible = false
	result_screen.visible = true


# --------------------------------------------------
# RESULT SCREEN ACTIONS
# --------------------------------------------------

func _on_retake_submit_pressed():
	var score := 0
	for i in range(quizzes.size()):
		if player_answers[i] == quizzes[i]["answer"]:
			score += 1
			
	# If player solved all riddles, emit solve signal and close
	if score == quizzes.size():
		puzzle_solved.emit(puzzle_id)
		puzzle_closed.emit(puzzle_id)
		# Optional: queue_free() or hide the puzzle overlay entirely here
	else:
		# Reset quiz state for a retake
		player_answers = [-1, -1, -1, -1]
		current_quiz = 0
		selected_option = -1
		save_progress()

		# Return back to the quiz interface
		quiz_container.visible = true
		result_screen.visible = false
		load_quiz(0)


func _on_close_button_pressed() -> void:
	save_progress()
	PuzzleManager.close_puzzle()
