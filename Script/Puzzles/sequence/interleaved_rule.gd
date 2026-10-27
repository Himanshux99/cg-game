class_name InterleavedRule
extends SequenceRule
## Two patterns are woven together: the 1st, 3rd, 5th... terms follow one arithmetic pattern
## and the 2nd, 4th, 6th... terms follow another.
## Parameter keys: start (first term of each pattern), step (size of each pattern's step).


func _init() -> void:
	family = "interleaved"
	min_revealed = 6
	default_max_abs = 300


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var step_a := _int_in(rng, config, "step", Vector2i(1, 9)) * _sign(rng)
	var step_b := _int_in(rng, config, "step", Vector2i(1, 9)) * _sign(rng)
	var start_a := _int_in(rng, config, "start", Vector2i(5, 80))
	var start_b := _int_in(rng, config, "start", Vector2i(5, 80))
	# Equal steps or close starts would blur the two patterns into one.
	if step_a == step_b or absi(start_a - start_b) < 3:
		return {}
	var terms: Array = []
	for i in range(total):
		if i % 2 == 0:
			terms.append(start_a + step_a * (i >> 1))
		else:
			terms.append(start_b + step_b * (i >> 1))
	var explanation := "Two patterns take turns: the 1st, 3rd, 5th... terms change by %d each time, the 2nd, 4th, 6th... by %d." % [step_a, step_b]
	return _package(terms, explanation, {"steps": [step_a, step_b]})


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var steps: Array = ctx["steps"]
	var own_step: int = steps[index % 2]
	var other_step: int = steps[(index + 1) % 2]
	var previous := _at(terms, index - 1)
	var same_pattern := _at(terms, index - 2)
	return [
		previous + (previous - same_pattern),   # read the weave as a single pattern
		same_pattern + other_step,              # used the other pattern's step
		previous + own_step,                    # applied the step to the wrong neighbour
		same_pattern + own_step + 1,
		same_pattern + own_step - 1,
	]
