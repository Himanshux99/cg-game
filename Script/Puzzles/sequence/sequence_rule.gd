class_name SequenceRule
extends RefCounted
## Base class of a sequence family. A rule builds a whole sequence from random parameters and
## knows which wrong answers a player is likely to pick. To add a family: extend this class,
## override build() and mistakes(), then register it in SequenceGenerator.RULES.

var family := ""
## Terms that must be shown so the pattern is repeated at least twice.
var min_revealed := 6
var default_max_abs := 1000


## Returns {"terms": Array of int, "explanation": String, "ctx": Dictionary}, or {} when the
## random parameters turned out unusable. Must return exactly `total` terms.
func build(_rng: RandomNumberGenerator, _config: SequenceConfig, _total: int) -> Dictionary:
	return {}


## Plausible wrong values for terms[index]. May only use terms[0..index - 1] and ctx,
## the same information the player has. Impossible values are filtered by OptionGenerator.
func mistakes(_terms: Array, _index: int, _ctx: Dictionary) -> Array:
	return []


func _int_in(rng: RandomNumberGenerator, config: SequenceConfig, key: String, fallback: Vector2i) -> int:
	var bounds := config.range_for(family, key, fallback)
	return rng.randi_range(bounds.x, bounds.y)


func _start(rng: RandomNumberGenerator, config: SequenceConfig) -> int:
	return _int_in(rng, config, "start", config.start_range)


func _sign(rng: RandomNumberGenerator) -> int:
	return 1 if rng.randi() % 2 == 0 else -1


func _at(terms: Array, index: int) -> int:
	return int(terms[index]) if index >= 0 and index < terms.size() else 0


func _package(terms: Array, explanation: String, ctx: Dictionary) -> Dictionary:
	return {"terms": terms, "explanation": explanation, "ctx": ctx}
