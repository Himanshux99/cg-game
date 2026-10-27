class_name RecursiveRule
extends SequenceRule
## Each term is built from the terms before it: "fib" (the sum of the last two, plus a constant),
## "trib" (the sum of the last three) or "weighted" (last term + 2 x the one before it).
## Parameter keys: seed (the first terms), offset (the constant of "fib").


func _init() -> void:
	family = "recursive"
	min_revealed = 6
	default_max_abs = 700


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var variants := ["fib", "trib", "weighted"]
	var variant: String = variants[rng.randi() % variants.size()]
	var terms: Array = []
	var explanation := ""
	var offset := 0
	if variant == "fib":
		offset = _int_in(rng, config, "offset", Vector2i(1, 2)) * _sign(rng)
		terms = [_int_in(rng, config, "seed", Vector2i(1, 9)), _int_in(rng, config, "seed", Vector2i(1, 9))]
		for i in range(total - 2):
			terms.append(int(terms[-1]) + int(terms[-2]) + offset)
		explanation = "Each term is the sum of the two before it, %s %d." % ["plus" if offset > 0 else "minus", absi(offset)]
	elif variant == "trib":
		for i in range(3):
			terms.append(_int_in(rng, config, "seed", Vector2i(1, 6)))
		for i in range(total - 3):
			terms.append(int(terms[-1]) + int(terms[-2]) + int(terms[-3]))
		explanation = "Each term is the sum of the three before it."
	else:
		terms = [_int_in(rng, config, "seed", Vector2i(1, 6)), _int_in(rng, config, "seed", Vector2i(1, 6))]
		# A second term equal to the first, or double it, would read as a simpler pattern.
		if terms[1] == terms[0] or terms[1] == 2 * terms[0]:
			return {}
		for i in range(total - 2):
			terms.append(int(terms[-1]) + 2 * int(terms[-2]))
		explanation = "Each term is the previous term plus double the term before that."
	return _package(terms, explanation, {"variant": variant, "offset": offset})


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var one := _at(terms, index - 1)
	var two := _at(terms, index - 2)
	var three := _at(terms, index - 3)
	var four := _at(terms, index - 4)
	var offset: int = ctx["offset"]
	if ctx["variant"] == "fib":
		return [one + three + offset, one + two, one + two + 2 * offset, one + (one - two)]
	if ctx["variant"] == "trib":
		return [one + two, two + three + four, one + two + three + 1, one + three]
	return [one + two, 2 * one + two, one + 2 * three, one + (one - two)]
