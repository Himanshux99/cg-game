class_name OptionGenerator
extends RefCounted
## Builds the answer buttons of one question: the correct number plus distinct, plausible wrong
## ones. Wrong answers come from the rule's typical mistakes first, then from close numbers.


## Returns {"options": Array of int, "correct_index": int}, or {} if the result failed validation.
static func build(correct: int, mistakes: Array, rng: RandomNumberGenerator, config: SequenceConfig, max_abs: int) -> Dictionary:
	var wanted := config.options_per_question - 1
	var lowest := -max_abs if config.allow_negative else 0
	# Wrong answers far above the real one (or the sequence limit) would be easy to rule out.
	var highest := mini(int(max_abs * 1.25), maxi(correct * 2, correct + 25))
	var wrong: Array = []
	var candidates: Array = mistakes.duplicate()
	_shuffle(candidates, rng)
	for value in candidates:
		if wrong.size() >= wanted:
			break
		_try_add(wrong, value, correct, lowest, highest)
	# Close numbers fill the gaps, nearest first so they stay believable.
	var delta := 1
	while wrong.size() < wanted and delta <= highest - lowest:
		var pair: Array = [correct + delta, correct - delta]
		_shuffle(pair, rng)
		for value in pair:
			if wrong.size() < wanted:
				_try_add(wrong, value, correct, lowest, highest)
		delta += 1
	var options: Array = wrong.duplicate()
	options.append(correct)
	_shuffle(options, rng)
	if not is_valid(options, correct, config.options_per_question):
		return {}
	return {"options": options, "correct_index": options.find(correct)}


## Exactly the requested number of distinct integers, one of which is the correct answer.
static func is_valid(options: Array, correct: int, expected_count: int) -> bool:
	if options.size() != expected_count:
		return false
	var seen := {}
	var correct_count := 0
	for option in options:
		if typeof(option) != TYPE_INT or seen.has(option):
			return false
		seen[option] = true
		if option == correct:
			correct_count += 1
	return correct_count == 1


static func _try_add(wrong: Array, value: Variant, correct: int, lowest: int, highest: int) -> void:
	if typeof(value) != TYPE_INT:
		return
	if value == correct or value < lowest or value > highest or wrong.has(value):
		return
	wrong.append(value)


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = values[i]
		values[i] = values[j]
		values[j] = swap
