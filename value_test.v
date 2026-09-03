module ruby

fn test_scalar_value_constructors_and_accessors() {
	text := string_value('brew')
	assert text.type_name == 'String'
	assert text.as_string() == 'brew'

	boolean := bool_value(true)
	assert boolean.as_bool() or { false }

	integer := int_value(42)
	assert integer.as_int() or { 0 } == 42
	assert integer.as_float() or { 0.0 } == 42.0

	decimal := float_value(1.5)
	assert decimal.as_float() or { 0.0 } == 1.5
}

fn test_collection_and_structured_values() {
	items := array_value([string_value('one'), int_value(2)])
	decoded_items := items.as_array() or { panic(err) }
	assert decoded_items.len == 2
	assert decoded_items[0].as_string() == 'one'
	assert decoded_items[1].as_int() or { 0 } == 2

	values := map_value({
		'name': string_value('ruby')
	})
	decoded_values := values.as_map() or { panic(err) }
	assert decoded_values['name'] or { Value{} }.as_string() == 'ruby'

	object := structured_value('Package', 'ruby', {
		'version': '0.1.0'
	})
	assert object.attribute('version') or { '' } == '0.1.0'
}

fn test_value_accessors_reject_wrong_types() {
	if _ := string_value('not a bool').as_bool() {
		assert false, 'expected a type mismatch'
	} else {
		assert err.msg() == 'expected Bool, got String'
	}
}
