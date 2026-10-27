class_name HigherOrderRule
extends SequenceRule
## Third-order pattern: the gaps change, and the change of the gaps itself changes by a constant.
## Needs six terms so the constant third-order gap is seen three times.
## Parameter keys: start, first_gap, second_gap, third_gap.


func _init() -> void:
	family = "higher_order"
	min_revealed = 6
	default_max_abs = 1000


func build(rng: RandomNumberGenerator, config: SequenceConfig, total: int) -> Dictionary:
	var gap := _int_in(rng, config, "first_gap", Vector2i(1, 6))
	var second := _int_in(rng, config, "second_gap", Vector2i(1, 4))
	var third := _int_in(rng, config, "third_gap", Vector2i(1, 2))
	var terms: Array = [_start(rng, config)]
	var gaps: Array = []
	var second_gaps: Array = []
	for i in range(total - 1):
		gaps.append(gap)
		terms.append(int(terms[-1]) + gap)
		var change := second + third * i
		second_gaps.append(change)
		gap += change
	var explanation := "The gaps grow, and the growth itself grows by %d each time." % third
	return _package(terms, explanation, {"gaps": gaps, "second_gaps": second_gaps, "third": third})


func mistakes(terms: Array, index: int, ctx: Dictionary) -> Array:
	var gaps: Array = ctx["gaps"]
	var second_gaps: Array = ctx["second_gaps"]
	var third: int = ctx["third"]
	var previous := _at(terms, index - 1)
	var last_gap := _at(gaps, index - 2)
	var last_change := _at(second_gaps, index - 2)    # what the player has to work out
	var prior_change := _at(second_gaps, index - 3)   # the latest growth visible to the player
	return [
		previous + last_gap,                                  # assumed the gap stays the same
		previous + last_gap + prior_change,                   # assumed the growth stays the same
		previous + last_gap + prior_change + 2 * third,       # grew the growth too fast
		previous + last_gap + last_change + 1,
	]
