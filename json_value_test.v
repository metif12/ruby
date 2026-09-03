module ruby

fn test_json_value_round_trip_preserves_dynamic_types() {
	value := parse_json_value('{"name":"ruby","ready":true,"count":2,"items":["v",null]}') or {
		panic(err)
	}
	assert (value.map_data['name'] or { Value{} }).as_string() == 'ruby'
	assert (value.map_data['ready'] or { Value{} }).as_bool() or { false }
	assert (value.map_data['count'] or { Value{} }).as_int() or { 0 } == 2

	round_trip := parse_json_value(json_value_to_string(value)) or { panic(err) }
	items := (round_trip.map_data['items'] or { Value{} }).as_array() or { panic(err) }
	assert items.len == 2
	assert items[0].as_string() == 'v'
	assert items[1].type_name == 'NilClass'
}
