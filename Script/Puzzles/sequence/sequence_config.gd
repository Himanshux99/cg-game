class_name SequenceConfig
extends Resource
## Every tunable value of the queue-prediction mini-game lives here: how many terms are shown,
## how many predictions are required, which rule families may appear, parameter ranges and the
## numeric limits. Use for_difficulty() for the built-in presets or edit a saved .tres.

## Terms shown before the questions. A rule can ask for more (SequenceRule.min_revealed) so
## the pattern is always visible at least twice.
@export var revealed_terms := 6
## Next terms the player must guess. All of them must be right for the attempt to pass.
@export var predictions_required := 3
@export var options_per_question := 4
## Rule family ids that may be picked (see SequenceGenerator.RULES).
@export var families: Array[String] = ["differences", "alternating"]
## Default range of the first term. A family can override it with the "start" key of param_overrides.
@export var start_range := Vector2i(1, 40)
## Used for a family that has no entry in max_abs_by_family.
@export var default_max_abs := 1000
## Largest absolute value a sequence of the family may reach, e.g. {"mul_add": 500}.
## A sequence that goes beyond it is discarded and generated again.
@export var max_abs_by_family: Dictionary = {}
## Per-family overrides of the rule parameter ranges (values are Vector2i),
## e.g. {"differences": {"step": Vector2i(2, 4)}}. The keys are listed in each rule's script.
@export var param_overrides: Dictionary = {}
@export var allow_negative := false
## Wrong attempts allowed before the challenge ends. 0 means unlimited retries.
@export var max_failed_attempts := 0
## Generation tries before SequenceGenerator gives up and uses its safe fallback sequence.
@export var max_generation_tries := 200


func max_abs_for(family: String, fallback: int) -> int:
	return int(max_abs_by_family.get(family, fallback if fallback > 0 else default_max_abs))


func range_for(family: String, key: String, fallback: Vector2i) -> Vector2i:
	var overrides: Dictionary = param_overrides.get(family, {})
	var value: Variant = overrides.get(key, fallback)
	if value is Vector2i and value.x <= value.y:
		return value
	return fallback


static func for_difficulty(level: int) -> SequenceConfig:
	var config := SequenceConfig.new()
	config.max_abs_by_family = {
		"differences": 400,
		"alternating": 200,
		"interleaved": 300,
		"mul_add": 500,
		"recursive": 700,
		"higher_order": 1000,
	}
	match clampi(level, 0, 3):
		0:
			config.families = ["differences", "alternating"]
		1:
			config.families = ["differences", "alternating", "interleaved", "mul_add"]
		2:
			config.families = ["alternating", "interleaved", "mul_add", "recursive", "higher_order"]
			config.predictions_required = 4
		3:
			config.families = ["interleaved", "mul_add", "recursive", "higher_order"]
			config.predictions_required = 5
	return config
