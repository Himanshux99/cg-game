class_name SequenceGame
extends RefCounted
## Gameplay state of the queue-prediction mini-game, without any UI. The UI asks it for the
## current attempt, reports the player's choices and submits them; the game decides the outcome.
##
## One attempt = one generated sequence with `predictions_required` questions. All answers must
## be right. A wrong submission fails the attempt (and every choice made in it); the next attempt
## always starts from a brand new sequence.

enum State { PLAYING, FAILED, PASSED, EXHAUSTED }

const MAX_OPTION_REBUILDS := 20

var config: SequenceConfig
var state := State.PLAYING
var failed_attempts := 0
var attempt_number := 0
## Current attempt: {"revealed", "questions": [{"options", "correct_index", "answer"}], "explanation", "family"}
var attempt: Dictionary = {}
## Option index picked for each question, -1 while unanswered.
var selections: Array = []

var _rng := RandomNumberGenerator.new()
var _generator := SequenceGenerator.new()
var _previous_terms: Array = []


func _init(game_config: SequenceConfig = null, seed_value: int = -1) -> void:
	config = game_config if game_config != null else SequenceConfig.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	start_new_attempt()


## Throws away everything attempt-specific and builds a fresh sequence. Not allowed after the
## challenge has been passed or has run out of attempts.
func start_new_attempt() -> bool:
	if state == State.PASSED or state == State.EXHAUSTED:
		return false
	attempt = _build_attempt()
	attempt_number += 1
	selections.clear()
	for i in range(config.predictions_required):
		selections.append(-1)
	state = State.PLAYING
	return true


func question_count() -> int:
	return config.predictions_required


func select_option(question: int, option_index: int) -> bool:
	if state != State.PLAYING or question < 0 or question >= selections.size():
		return false
	var options: Array = attempt["questions"][question]["options"]
	if option_index < 0 or option_index >= options.size():
		return false
	selections[question] = option_index
	return true


func is_complete() -> bool:
	return not selections.has(-1)


## Mistakes still allowed, or -1 when retries are unlimited.
func attempts_left() -> int:
	if config.max_failed_attempts <= 0:
		return -1
	return maxi(0, config.max_failed_attempts - failed_attempts)


## Checks the answers. Returns {"accepted": bool, "passed": bool, "results": Array of bool}.
## An incomplete submission, or any submission after the attempt was decided, is rejected without
## changing anything, so a pass can never be counted twice.
func submit() -> Dictionary:
	if state != State.PLAYING or not is_complete():
		return {"accepted": false, "passed": false, "results": []}
	var results: Array = []
	var all_correct := true
	for i in range(selections.size()):
		var question: Dictionary = attempt["questions"][i]
		var right: bool = selections[i] == question["correct_index"]
		results.append(right)
		all_correct = all_correct and right
	if all_correct:
		state = State.PASSED
	else:
		failed_attempts += 1
		var out_of_attempts := config.max_failed_attempts > 0 and failed_attempts >= config.max_failed_attempts
		state = State.EXHAUSTED if out_of_attempts else State.FAILED
	return {"accepted": true, "passed": all_correct, "results": results}


func _build_attempt() -> Dictionary:
	var built: Dictionary = {}
	for _try in range(MAX_OPTION_REBUILDS):
		var sequence := _generator.generate(config, _rng, _previous_terms)
		built = _build_questions(sequence)
		if not built.is_empty():
			break
	if built.is_empty():
		# Practically unreachable: option building only fails on a broken config. Keep the last
		# sequence with plain neighbouring numbers instead of looping forever.
		built = _build_questions(_generator.generate(config, _rng, []), true)
	if built.is_empty():
		push_error("SequenceGame: could not build answer options, check SequenceConfig.options_per_question and max values.")
		built = {"terms": [], "revealed": [], "questions": [], "explanation": "", "family": ""}
	_previous_terms = built["terms"]
	return built


func _build_questions(sequence: Dictionary, plain: bool = false) -> Dictionary:
	var rule: SequenceRule = sequence["rule"]
	var terms: Array = sequence["terms"]
	var revealed: Array = sequence["revealed"]
	var questions: Array = []
	for k in range(sequence["answers"].size()):
		var index := revealed.size() + k
		var mistakes: Array = [] if plain else rule.mistakes(terms, index, sequence["ctx"])
		var built := OptionGenerator.build(int(terms[index]), mistakes, _rng, config, sequence["max_abs"])
		if built.is_empty():
			return {}
		questions.append({
			"options": built["options"],
			"correct_index": built["correct_index"],
			"answer": int(terms[index]),
		})
	return {
		"terms": terms,
		"revealed": revealed,
		"questions": questions,
		"explanation": sequence["explanation"],
		"family": sequence["family"],
	}
