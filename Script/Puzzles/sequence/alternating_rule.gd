class_name AlternatingRule
extends SequenceRule
## Two operations take turns: add a, subtract b (or the other way round).
## Parameter keys: start, up (the amount added), down (the amount subtracted, kept below up).


func _init() -> void:
	family = "alternating"
	min_revealed = 6
	default_max_abs = 200


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var up := _int_in(rng, config, "up", Vector2i(3, 15))
	var down := _int_in(rng, config, "down", Vector2i(1, maxi(1, up - 1)))
	# Equal amounts would cancel out and the sequence would just bounce between two values.
	if up == down:
		return {}
	var up_first := rng.randi() % 2 == 0
	var steps: Array = []
	for i in range(total - 1):
		var is_up := (i % 2 == 0) == up_first
		steps.append(up if is_up else -down)
	var terms: Array = [_start(rng, config)]
	for step in steps:
		terms.append(int(terms[-1]) + int(step))
	var explanation := ""
	if up_first:
		explanation = "Add %d, then subtract %d, and repeat." % [up, down]
	else:
		explanation = "Subtract %d, then add %d, and repeat." % [down, up]
	return _package(terms, explanation, {"up": up, "down": down, "steps": steps})


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var previous := _at(terms, index - 1)
	var steps: Array = ctx["steps"]
	var true_step: int = steps[index - 1]
	var up: int = ctx["up"]
	var down: int = ctx["down"]
	return [
		previous + _at(steps, index - 2),   # repeated the previous operation
		previous - true_step,               # used the opposite operation
		previous + up - down,               # merged both operations into one
		previous + true_step + 1,
		previous + true_step - 1,
	]
