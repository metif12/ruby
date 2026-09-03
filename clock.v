module ruby

import time

pub fn today_iso() string {
	now := time.now()
	return '${now.year:04d}-${now.month:02d}-${now.day:02d}'
}
