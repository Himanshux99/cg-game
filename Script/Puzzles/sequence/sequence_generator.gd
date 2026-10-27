class_name SequenceGenerator
extends RefCounted
## Builds a valid sequence for the mini-game: picks a rule family, lets the rule build the
## whole sequence, then rejects anything outside the family's number limit or too ambiguous.
## Generation is bounded (SequenceConfig.max_generation_tries) and ends in a safe fallback.

## Family id -> rule script. Register new families here.
const RULES := {
	"differences": preload("res://Script/Puzzles/sequence/difference_rule.gd"),
	"alternating": preload("res://Script/Puzzles/sequence/alternating_rule.gd"),
	"interleaved": preload("res://Script/Puzzles/sequence/interleaved_rule.gd"),
	"mul_add": preload("res://Script/Puzzles/sequence/mul_add_rule.gd"),
	"recursive": preload("res://Script/Puzzles/sequence/recursive_rule.gd"),
	"higher_order": preload("res://Script/Puzzles/sequence/higher_order_rule.gd"),
}


## Returns {"family", "rule", "explanation", "ctx", "terms", "revealed", "answers", "max_abs", "fallback"}.
## `previous` is the terms of the last attempt; the new sequence is never identical to it.
func generate(config: SequenceConfig, rng: RandomNumberGenerator, previous: Array = []) -> Dictionary:
	var families := _usable_families(config)
	for _try in range(config.max_generation_tries):
		var family: String = families[rng.randi() % families.size()]
		var rule: SequenceRule = RULES[family].new()
		var revealed_count := maxi(config.revealed_terms, rule.min_revealed)
		var total := revealed_count + config.predictions_required
		var built := rule.build(rng, config, total)
		if built.is_empty():
			continue
		var terms: Array = built["terms"]
		var max_abs := config.max_abs_for(family, rule.default_max_abs)
		if not is_valid(terms, revealed_count, total, max_abs, config.allow_negative):
			continue
		if terms == previous:
			continue
		return _package(family, rule, built, terms, revealed_count, max_abs, false)
	return _fallback(config)


## A sequence is accepted only when it has every term, stays inside +-max_abs (and above zero
## unless negatives are allowed) and its revealed part is not a plain constant, arithmetic or
## geometric run that many rules could explain.
func is_valid(terms: Array, revealed_count: int, total: int, max_abs: int, allow_negative: bool) -> bool:
	if terms.size() != total or revealed_count < 3 or revealed_count >= total:
		return false
	for term in terms:
		if typeof(term) != TYPE_INT:
			return false
		if absi(term) > max_abs or (term < 0 and not allow_negative):
			return false
	return not _is_trivial(terms.slice(0, revealed_count))


func _is_trivial(revealed: Array) -> bool:
	var gap_count := revealed.size() - 1
	var same_gap := true
	var same_ratio := true
	for i in range(1, gap_count):
		if revealed[i + 1] - revealed[i] != revealed[1] - revealed[0]:
			same_gap = false
		# Ratio test in integers: a / b == c / d  <=>  a * d == b * c.
		if revealed[i + 1] * revealed[0] != revealed[i] * revealed[1]:
			same_ratio = false
	return same_gap or (same_ratio and revealed[0] != 0)


func _usable_families(config: SequenceConfig) -> Array:
	var usable: Array = []
	for family in config.families:
		if RULES.has(family):
			usable.append(family)
	if usable.is_empty():
		usable.append("differences")
	return usable


## Used only when every try failed (an extreme config): a slow-growing second-order sequence
## that fits the usual limits.
func _fallback(config: SequenceConfig) -> Dictionary:
	var rule: SequenceRule = RULES["differences"].new()
	var revealed_count := maxi(config.revealed_terms, rule.min_revealed)
	var total := revealed_count + config.predictions_required
	var terms: Array = [1]
	var gaps: Array = []
	for i in range(total - 1):
		gaps.append(1 + i)
		terms.append(int(terms[-1]) + 1 + i)
	var built := {
		"terms": terms,
		"explanation": "The gap grows by 1 each time.",
		"ctx": {"variant": "linear", "step": 1, "gaps": gaps},
	}
	return _package("differences", rule, built, terms, revealed_count, maxi(terms[-1], 1), true)


func _package(family: String, rule: SequenceRule, built: Dictionary, terms: Array, revealed_count: int, max_abs: int, fallback: bool) -> Dictionary:
	return {
		"family": family,
		"rule": rule,
		"explanation": built["explanation"],
		"ctx": built["ctx"],
		"terms": terms,
		"revealed": terms.slice(0, revealed_count),
		"answers": terms.slice(revealed_count),
		"max_abs": max_abs,
		"fallback": fallback,
	}
