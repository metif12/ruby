module ruby

fn test_captured_command_keeps_stdout_stderr_and_exit_status_separate() {
	result := run_captured_command(['/bin/sh', '-c', 'printf output; printf error >&2; exit 7'], CapturedCommandOptions{
		environment: environment()
	}) or { panic(err) }
	assert result.exit_code == 7
	assert result.stdout == 'output'
	assert result.stderr == 'error'
}

fn test_run_command_passes_arguments_without_shell_interpolation() {
	result := run_command('/bin/echo', ['hello world'])
	assert result.exit_code == 0
	assert result.output.trim_space() == 'hello world'
}
