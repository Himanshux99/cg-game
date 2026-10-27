class_name DifferenceRule
extends SequenceRule
## The gaps between neighbours follow a pattern: either they grow / shrink by a fixed amount
## ("linear") or they repeat a short cycle of three gaps ("cycle").
## Parameter keys: start, step (size of the change), first_gap, first_gap_down, cycle_gap.


func _init() -> void:
	family = "differences"
	min_revealed = 6
	default_max_abs = 400


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var gaps: Array = []
	var explanation := ""
	var ctx := {}
	if rng.randi() % 2 == 0:
		var step := _int_in(rng, config, "step", Vector2i(2, 5)) * _sign(rng)
		var first := 0
		if step > 0:
			first = _int_in(rng, config, "first_gap", Vector2i(1, 8))
		else:
			first = _int_in(rng, config, "first_gap_down", Vector2i(14, 30))
		for i in range(total - 1):
			gaps.append(first + step * i)
		if step > 0:
			explanation = "The gap grows by %d each time." % step
		else:
			explanation = "The gap shrinks by %d each time." % -step
		ctx = {"variant": "linear", "step": step}
	else:
		var bounds := config.range_for(family, "cycle_gap", Vector2i(1, 12))
		var pool: Array = range(bounds.x, bounds.y + 1)
		if pool.size() < 3:
			return {}
		var cycle: Array = []
		while cycle.size() < 3:
			var pick: int = pool[rng.randi() % pool.size()]
			if not cycle.has(pick):
				cycle.append(pick)
		for i in range(total - 1):
			gaps.append(cycle[i % 3])
		explanation = "The gaps repeat: +%d, +%d, +%d." % [cycle[0], cycle[1], cycle[2]]
		ctx = {"variant": "cycle", "cycle": cycle}
	var terms: Array = [_start(rng, config)]
	for gap in gaps:
		terms.append(int(terms[-1]) + int(gap))
	ctx["gaps"] = gaps
	return _package(terms, explanation, ctx)


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var previous := _at(terms, index - 1)
	var gaps: Array = ctx["gaps"]
	var true_gap: int = gaps[index - 1]
	var wrong: Array = []
	if ctx["variant"] == "linear":
		var step: int = ctx["step"]
		wrong.append(previous + _at(gaps, index - 2))       # forgot that the gap changes
		wrong.append(previous + true_gap + step)            # changed the gap one step too far
		wrong.append(previous + true_gap - step)            # changed the gap one step too little
		wrong.append(previous + true_gap - 2 * step)
	else:
		for gap in ctx["cycle"]:
			if gap != true_gap:
				wrong.append(previous + int(gap))           # right gaps, wrong place in the cycle
		wrong.append(previous + true_gap + 1)
	return wrong
