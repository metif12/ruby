module ruby

fn test_today_iso_has_an_iso_calendar_shape() {
	today := today_iso()
	assert today.len == 10
	assert today[4] == `-`
	assert today[7] == `-`
}
