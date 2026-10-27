class_name MulAddRule
extends SequenceRule
## Multiplication mixed with addition or subtraction: either every step is "x m, then + c"
## ("chain") or the steps alternate between "x m" and "+ c" / "- c" ("alternating").
## Parameter keys: start, multiplier, offset.


func _init() -> void:
	family = "mul_add"
	min_revealed = 6
	default_max_abs = 500


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var multiplier := _int_in(rng, config, "multiplier", Vector2i(2, 3))
	var offset := _int_in(rng, config, "offset", Vector2i(1, 9))
	var terms: Array = [_start(rng, config)]
	var explanation := ""
	var variant := "chain"
	offset *= _sign(rng)
	if rng.randi() % 2 == 0:
		for i in range(total - 1):
			terms.append(int(terms[-1]) * multiplier + offset)
		explanation = "Multiply by %d, then %s %d." % [multiplier, "add" if offset > 0 else "subtract", absi(offset)]
	else:
		variant = "alternating"
		for i in range(total - 1):
			if i % 2 == 0:
				terms.append(int(terms[-1]) * multiplier)
			else:
				terms.append(int(terms[-1]) + offset)
		explanation = "Multiply by %d, then %s %d, and repeat." % [multiplier, "add" if offset > 0 else "subtract", absi(offset)]
	return _package(terms, explanation, {"variant": variant, "multiplier": multiplier, "offset": offset})


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var previous := _at(terms, index - 1)
	var multiplier: int = ctx["multiplier"]
	var offset: int = ctx["offset"]
	return [
		previous * multiplier,                # only multiplied
		previous + offset,                    # only added / subtracted
		previous * multiplier + offset,       # did both in one step
		previous * multiplier - offset,       # wrong sign on the offset
		previous * (multiplier + 1) + offset,
		previous + 2 * offset,
		previous + multiplier,
		previous * multiplier + 2 * offset,
	]
