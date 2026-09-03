module ruby

import x.json2

// json_value_from_any preserves dynamically typed JSON data at translated API boundaries.
pub fn json_value_from_any(value json2.Any) Value {
	return match value {
		string { string_value(value) }
		bool { bool_value(value) }
		int { int_value(value) }
		i64 { int_value(value) }
		u64 { int_value(i64(value)) }
		f64 {
			if value == f64(i64(value)) { int_value(i64(value)) } else { float_value(value) }
		}
		[]json2.Any { array_value(value.map(json_value_from_any(it))) }
		map[string]json2.Any {
			mut converted := map[string]Value{}
			for key, entry in value {
				converted[key] = json_value_from_any(entry)
			}
			map_value(converted)
		}
		else { Value{ type_name: 'NilClass', repr: 'nil' } }
	}
}

pub fn json_any_from_value(value Value) json2.Any {
	return match value.type_name {
		'NilClass' { json2.null }
		'Bool' { json2.Any(value.bool_data) }
		'Integer' { json2.Any(value.int_data) }
		'Float' { json2.Any(value.float_data) }
		'Array' {
			entries := value.as_array() or { []Value{} }
			json2.Any(entries.map(json_any_from_value(it)))
		}
		'Hash' {
			mut converted := map[string]json2.Any{}
			for key, entry in value.map_data {
				converted[key] = json_any_from_value(entry)
			}
			json2.Any(converted)
		}
		else { json2.Any(value.as_string()) }
	}
}

pub fn parse_json_value(contents string) !Value {
	decoded := json2.decode[json2.Any](contents)!
	return json_value_from_any(decoded)
}

// json_value_to_string serializes a translated JSON boundary without losing
// integer, Boolean, array, map, or null types.
pub fn json_value_to_string(value Value) string {
	return json2.encode(json_any_from_value(value))
}
