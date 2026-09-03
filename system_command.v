module ruby

import os
import time

// CapturedCommandOptions isolates native process management from translated
// modules where a source `os` namespace shadows V's standard `os` module.
pub struct CapturedCommandOptions {
pub:
	environment map[string]string
	input       string
	chdir       string
	timeout     ?time.Duration
	use_pgroup  bool
}

pub struct CapturedCommandResult {
pub:
	exit_code int
	stdout    string
	stderr    string
}

pub fn environment() map[string]string {
	return os.environ()
}

pub fn environment_value_opt(name string) ?string {
	return os.getenv_opt(name)
}

pub fn absolute_path(path string) string {
	return os.abs_path(path)
}

fn captured_command_temp_directory() string {
	return os.join_path(os.temp_dir(), 'v-ruby-system-command-${os.getpid()}-${time.now().unix_nano()}')
}

// run_captured_command executes argv without interpolating it. The shell only
// installs file redirections; the executable and arguments remain positional
// parameters passed directly to `exec`.
pub fn run_captured_command(argv []string, options CapturedCommandOptions) !CapturedCommandResult {
	if argv.len == 0 {
		return error('command cannot be empty')
	}
	temporary_path := captured_command_temp_directory()
	os.mkdir(temporary_path)!
	defer {
		os.rmdir_all(temporary_path) or {}
	}
	stdin_path := os.join_path(temporary_path, 'stdin')
	stdout_path := os.join_path(temporary_path, 'stdout')
	stderr_path := os.join_path(temporary_path, 'stderr')
	os.write_file(stdin_path, options.input)!
	os.write_file(stdout_path, '')!
	os.write_file(stderr_path, '')!
	mut process_environment := options.environment.clone()
	process_environment['V_RUBY_SYSTEM_COMMAND_STDIN'] = stdin_path
	process_environment['V_RUBY_SYSTEM_COMMAND_STDOUT'] = stdout_path
	process_environment['V_RUBY_SYSTEM_COMMAND_STDERR'] = stderr_path
	mut process := os.new_process('/bin/sh')
	mut process_args := ['-c',
		'exec "\$@" < "\$V_RUBY_SYSTEM_COMMAND_STDIN" > "\$V_RUBY_SYSTEM_COMMAND_STDOUT" 2> "\$V_RUBY_SYSTEM_COMMAND_STDERR"',
		'v-ruby-system-command']
	process_args << argv
	process.set_args(process_args)
	process.set_environment(process_environment)
	if options.chdir != '' {
		if !os.is_dir(options.chdir) {
			return error('No such working directory: ${options.chdir}')
		}
		process.set_work_folder(options.chdir)
	}
	process.use_pgroup = options.use_pgroup
	process.run()
	if process.status == .aborted || process.err != '' {
		message := process.err
		process.close()
		if message == '' {
			return error('failed to start ${argv[0]}')
		}
		return error(message)
	}
	if timeout := options.timeout {
		deadline := time.now().add(timeout)
		for process.is_alive() && time.now() < deadline {
			time.sleep(5 * time.millisecond)
		}
		if process.is_alive() {
			if process.use_pgroup {
				process.signal_pgkill()
			} else {
				process.signal_kill()
			}
			process.wait()
			process.close()
			return error('System command timed out: ${argv[0]}')
		}
	}
	process.wait()
	exit_code := process.code
	process.close()
	return CapturedCommandResult{
		exit_code: exit_code
		stdout: os.read_file(stdout_path)!
		stderr: os.read_file(stderr_path)!
	}
}
