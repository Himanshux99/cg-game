extends SceneTree
## Headless checks for the queue-prediction mini-game.
## Run from the project folder:  godot --headless --path . -s res://Script/tests/test_sequence_game.gd
## (run `godot --headless --path . --import` once first so the new class names are registered).

var _failures := 0
var _checks := 0


func _init() -> void:
	_test_every_family()
	_test_limits_and_fallback()
	_test_options()
	_test_pass_flow()
	_test_fail_flow()
	_test_invalid_submissions()
	_test_unlimited_attempts()
	_test_attempt_limit()
	print("%d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _config_for(family: String, predictions: int) -> SequenceConfig:
	var config := SequenceConfig.for_difficulty(3)
	config.families = [family]
	config.predictions_required = predictions
	return config


func _correct_picks(game: SequenceGame) -> void:
	for q in range(game.question_count()):
		game.select_option(q, game.attempt["questions"][q]["correct_index"])


func _wrong_picks(game: SequenceGame) -> void:
	for q in range(game.question_count()):
		var correct: int = game.attempt["questions"][q]["correct_index"]
		game.select_option(q, (correct + 1) % game.config.options_per_question)


# Every family, 3 to 5 predictions: limits, answer key and options.
func _test_every_family() -> void:
	for family in SequenceGenerator.RULES.keys():
		for predictions in [3, 4, 5]:
			var config := _config_for(family, predictions)
			var generator := SequenceGenerator.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 1234 + predictions
			for i in range(150):
				var sequence := generator.generate(config, rng)
				var label := "%s/%d" % [family, predictions]
				var terms: Array = sequence["terms"]
				var limit: int = sequence["max_abs"]
				_check(sequence["family"] == family, label + " family")
				_check(sequence["answers"].size() == predictions, label + " answer count")
				_check(sequence["revealed"].size() >= 5, label + " revealed count")
				_check(terms == sequence["revealed"] + sequence["answers"], label + " answers come from the same sequence")
				var within := true
				for term in terms:
					within = within and typeof(term) == TYPE_INT and term >= 0 and term <= limit
				_check(within, label + " stays within limits %s" % [terms])
				_check(not sequence["fallback"], label + " needed no fallback")


# A limit nothing can satisfy must end in the fallback, not in an endless loop.
func _test_limits_and_fallback() -> void:
	var config := _config_for("mul_add", 5)
	config.max_abs_by_family = {"mul_add": 5}
	config.max_generation_tries = 50
	var sequence := SequenceGenerator.new().generate(config, RandomNumberGenerator.new())
	_check(sequence["fallback"], "impossible limit falls back")
	_check(sequence["answers"].size() == 5, "fallback has all predictions")
	# A too-small limit makes plain generations fail validation.
	var generator := SequenceGenerator.new()
	_check(not generator.is_valid([1, 2, 4, 8, 16, 33, 66, 140, 290], 6, 9, 100, false), "over-limit sequence rejected")
	_check(not generator.is_valid([2, 4, 6, 8, 10, 12, 14, 16, 18], 6, 9, 100, false), "arithmetic reveal rejected")
	_check(not generator.is_valid([2, 4, 8, 16, 32, 64, 128, 256, 512], 6, 9, 1000, false), "geometric reveal rejected")
	_check(not generator.is_valid([5, 3, 9, 4, 8, 2, 7, 1, -3], 6, 9, 100, false), "negative term rejected")


func _test_options() -> void:
	var config := SequenceConfig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(300):
		var correct := rng.randi_range(0, 400)
		var built := OptionGenerator.build(correct, [correct, correct, -5, 99999], rng, config, 400)
		_check(not built.is_empty(), "options built for %d" % correct)
		_check(OptionGenerator.is_valid(built["options"], correct, 4), "options valid for %d" % correct)
		_check(built["options"][built["correct_index"]] == correct, "correct index for %d" % correct)
		for option in built["options"]:
			_check(option >= 0, "no negative option for %d" % correct)
	_check(not OptionGenerator.is_valid([1, 2, 2, 3], 1, 4), "duplicate options rejected")
	_check(not OptionGenerator.is_valid([1, 2, 3, 4], 9, 4), "missing correct option rejected")


func _test_pass_flow() -> void:
	var game := SequenceGame.new(_config_for("differences", 3), 11)
	_correct_picks(game)
	var result := game.submit()
	_check(result["accepted"] and result["passed"], "all correct passes")
	_check(game.state == SequenceGame.State.PASSED, "state is PASSED")
	_check(not game.submit()["accepted"], "second submit after a pass is rejected")
	_check(not game.start_new_attempt(), "no new attempt after a pass")
	_check(not game.select_option(0, 0), "no changes after a pass")


func _test_fail_flow() -> void:
	var game := SequenceGame.new(_config_for("recursive", 4), 21)
	var first_terms: Array = game.attempt["terms"]
	_correct_picks(game)
	game.select_option(2, (game.attempt["questions"][2]["correct_index"] + 1) % 4)   # one wrong answer fails all
	var result := game.submit()
	_check(result["accepted"] and not result["passed"], "one wrong answer fails the attempt")
	_check(game.state == SequenceGame.State.FAILED and game.failed_attempts == 1, "failure is counted")
	_check(not game.submit()["accepted"], "no resubmitting a failed attempt")
	_check(game.start_new_attempt(), "retry allowed after a failure")
	_check(game.state == SequenceGame.State.PLAYING, "playing again")
	_check(game.selections == [-1, -1, -1, -1], "answers are reset")
	_check(game.attempt["terms"] != first_terms, "a fresh sequence is generated")
	_check(game.attempt_number == 2, "attempt counter advanced")


func _test_invalid_submissions() -> void:
	var game := SequenceGame.new(_config_for("alternating", 3), 31)
	_check(not game.submit()["accepted"], "empty submission rejected")
	game.select_option(0, game.attempt["questions"][0]["correct_index"])
	_check(not game.submit()["accepted"], "incomplete submission rejected")
	_check(not game.select_option(3, 0), "question out of range rejected")
	_check(not game.select_option(0, 9), "option out of range rejected")
	_check(not game.select_option(0, -1), "negative option rejected")
	_check(game.failed_attempts == 0, "rejected submissions cost nothing")


func _test_unlimited_attempts() -> void:
	var game := SequenceGame.new(_config_for("differences", 3), 51)
	_check(game.config.max_failed_attempts == 0 and game.attempts_left() == -1, "unlimited by default")
	for i in range(60):
		_wrong_picks(game)
		game.submit()
		_check(game.state == SequenceGame.State.FAILED, "mistake %d does not end the challenge" % (i + 1))
		game.start_new_attempt()
	_check(game.state == SequenceGame.State.PLAYING, "still playing after 60 mistakes")


func _test_attempt_limit() -> void:
	var config := _config_for("interleaved", 3)
	config.max_failed_attempts = 3
	var game := SequenceGame.new(config, 41)
	for i in range(3):
		_check(game.state == SequenceGame.State.PLAYING, "still playing before mistake %d" % (i + 1))
		_wrong_picks(game)
		game.submit()
		if i < 2:
			game.start_new_attempt()
	_check(game.state == SequenceGame.State.EXHAUSTED, "attempt limit ends the challenge")
	_check(game.attempts_left() == 0, "no attempts left")
	_check(not game.start_new_attempt(), "no new attempt once exhausted")
