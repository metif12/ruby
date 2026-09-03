module ruby

import os
import time

fn test_filesystem_helpers_read_and_replace_files() {
	root := os.join_path(os.temp_dir(), 'v-ruby-filesystem-${os.getpid()}-${time.now().unix_micro()}')
	make_dir_all(root) or { panic(err) }
	defer {
		remove_all(root) or {}
	}

	path := join_path(root, 'value.txt')
	write_file(path, 'first') or { panic(err) }
	assert path_exists(path)
	assert is_file(path)
	assert read_file(path) or { '' } == 'first'

	atomic_write_file(path, 'second') or { panic(err) }
	assert read_file(path) or { '' } == 'second'
	assert 'value.txt' in (list_dir(root) or { []string{} })
}
