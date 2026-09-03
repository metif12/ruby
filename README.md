# ruby

`ruby` is a small compatibility and runtime module for translating Ruby
programs to V. It is not a Ruby interpreter.

The module currently provides:

- a dynamic `Value` type for boundaries that have not yet been converted to
  concrete V types;
- conversion between `Value` and dynamically typed JSON;
- filesystem, environment, clock, and process helpers used by translated code;
- an explicit `unimplemented_fn` boundary for incomplete translations.

Install it directly from GitHub:

```sh
v install --git https://github.com/vlang/ruby
```

Then import it as a normal V module:

```v
import ruby

pub fn translated_name(args ...ruby.Value) ruby.Value {
	if args.len == 0 {
		return ruby.object_value('NilClass', 'nil')
	}
	return ruby.string_value(args[0].as_string())
}
```

Run the module tests with:

```sh
v test .
```

## License

BSD-2-Clause
