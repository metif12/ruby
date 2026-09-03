module ruby

import os
import readline

// read_file isolates V's standard-library filesystem module from translated
// source namespaces that may also use the name `os`.
pub fn read_file(path string) !string {
	return os.read_file(path)
}

// read_bytes preserves arbitrary data while keeping V's standard-library `os`
// namespace isolated from a translated source module with the same name.
pub fn read_bytes(path string) ![]u8 {
	return os.read_bytes(path)
}

pub fn is_file(path string) bool {
	return os.is_file(path)
}

pub fn is_dir(path string) bool {
	return os.is_dir(path)
}

pub fn is_link(path string) bool {
	return os.is_link(path)
}

pub fn path_exists(path string) bool {
	return os.exists(path)
}

pub fn join_path(first string, second string) string {
	return os.join_path(first, second)
}

pub fn list_dir(path string) ![]string {
	return os.ls(path)
}

pub fn real_path(path string) string {
	return os.real_path(path)
}

pub fn find_executable(name string) !string {
	return os.find_abs_path_of_executable(name)
}

pub fn environment_value(name string) string {
	return os.getenv(name)
}

// effective_uid exposes Process.euid without importing V's `os` module into a
// translated module where the source's own `os` namespace shadows it.
pub fn effective_uid() int {
	return os.geteuid()
}

pub fn current_username() string {
	username := os.user_os()
	return if username != '' { username } else { os.getenv('USER') }
}

pub fn current_directory() string {
	return os.getwd()
}

// file_owner_uid is the typed equivalent of Ruby's `Pathname#stat.uid`.
pub fn file_owner_uid(path string) !int {
	file_stat := os.stat(path)!
	return int(file_stat.uid)
}

pub interface AppManagementPermissionCommand {
	touch_and_remove_with_sudo(path string) !
}

// app_management_permissions_granted implements a translated macOS application
// permission probe. The command boundary is injected because the source uses
// sudo to trigger App Management for non-writable applications.
pub fn app_management_permissions_granted(app string,
	command AppManagementPermissionCommand) !bool {
	if !os.is_dir(app) {
		return true
	}
	test_file := os.join_path(app, '.homebrew-write-test')
	file_stat := os.lstat(app)!
	mode := int(file_stat.get_mode().bitmask())
	mut group_ids := [os.getgid(), os.getegid()]
	group_result := run_command('/usr/bin/id', ['-G'])
	if group_result.exit_code == 0 {
		for raw in group_result.output.trim_space().split(' ') {
			if raw != '' {
				group_ids << raw.int()
			}
		}
	}
	looks_writable_without_sudo := if int(file_stat.uid) == os.geteuid() {
		mode & 0o200 != 0
	} else if int(file_stat.gid) in group_ids {
		mode & 0o020 != 0
	} else {
		mode & 0o002 != 0
	}
	if looks_writable_without_sudo {
		os.write_file(test_file, '') or { return false }
		os.rm(test_file) or { return false }
		return true
	}
	command.touch_and_remove_with_sudo(test_file) or {
		if err.msg().contains('touch: ${test_file}: Operation not permitted') {
			return false
		}
		return err
	}
	return true
}

pub fn make_dir_all(path string) ! {
	os.mkdir_all(path)!
}

pub fn remove_all(path string) ! {
	os.rmdir_all(path)!
}

pub fn temporary_directory() string {
	return os.temp_dir()
}

pub fn write_file(path string, contents string) ! {
	os.write_file(path, contents)!
}

// atomic_write_file mirrors Ruby's common atomic-write pattern: write beside
// the destination and rename only after the write succeeds.
pub fn atomic_write_file(path string, contents string) ! {
	temporary_path := '${path}.v-ruby-${os.getpid()}'
	os.write_file(temporary_path, contents)!
	os.mv(temporary_path, path) or {
		os.rm(temporary_path) or {}
		return err
	}
}

pub fn process_arguments() []string {
	return os.args[1..].clone()
}

pub fn process_id() int {
	return os.getpid()
}

pub fn stdout_is_terminal() bool {
	return os.is_atty(1) > 0
}

pub fn stdin_is_terminal() bool {
	return os.is_atty(0) > 0
}

// read_terminal_character is the V equivalent of Ruby's IO#getch. It puts the
// terminal in raw mode only for the duration of one read and restores the
// original terminal settings before returning, including on read failure.
pub fn read_terminal_character() !int {
	mut reader := readline.Readline{}
	reader.enable_raw_mode()
	defer {
		reader.disable_raw_mode()
	}
	return reader.read_char()!
}

pub struct KernelInfo {
pub:
	name    string
	release string
}

pub fn kernel_info() KernelInfo {
	information := os.uname()
	return KernelInfo{
		name: information.sysname
		release: information.release
	}
}

pub struct CommandResult {
pub:
	exit_code int
	output    string
}

// run_command executes an argument vector without shell interpolation.
pub fn run_command(program string, arguments []string) CommandResult {
	mut command := []string{cap: arguments.len + 1}
	command << program
	command << arguments
	result := os.exec(command)
	return CommandResult{
		exit_code: result.exit_code
		output: result.output
	}
}

// run_command_with_environment overlays source-provided variables on the
// current process environment, matching Homebrew's safe_popen_read contract.
pub fn run_command_with_environment(program string, arguments []string,
	environment map[string]string) CommandResult {
	mut names := environment.keys()
	names.sort()
	mut command := []string{cap: environment.len + arguments.len + 2}
	command << '/usr/bin/env'
	for name in names {
		command << '${name}=${environment[name]}'
	}
	command << program
	command << arguments
	result := os.exec(command)
	return CommandResult{
		exit_code: result.exit_code
		output: result.output
	}
}
