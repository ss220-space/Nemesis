/atom/movable/screen/escape_menu/details
	screen_loc = "EAST:-175,NORTH:-40"
	maptext_height = 100
	maptext_width = 200

/atom/movable/screen/escape_menu/details/proc/update_text(client/client_owner)
	var/new_maptext = {"
		<span style='text-align: right; line-height: 0.7'>
			ID раунда: [GLOB.round_id || "Unset"]<br />
			Серверное время (NST): [server_timestamp(format = "hh:mm:ss", ic_time = TRUE, twelve_hour_clock = client_owner.prefs.read_preference(/datum/preference/toggle/twelve_hour))]<br />
			Внутриигровое время (PT): [(SSticker.round_start_time == 0) ? "Pre-Game" : round_timestamp()]<br />
			Карта: [SSmapping.current_map.return_map_name(webmap_included = TRUE) || "Загрузка..."]<br />
			Задержка времени: [round(SStime_track.time_dilation_current, 1)]%<br />
		</span>
	"}

	maptext = MAPTEXT(new_maptext)
