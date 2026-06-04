/datum/escape_menu/proc/show_admin_page()
	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/lobby_button/small(
			null,
			/* hud_owner = */ null,
			"Вернуться",
			/* tooltip_text = */ null,
			/* button_screen_loc = */ "TOP:-30,LEFT:30",
			CALLBACK(src, PROC_REF(open_home_page)),
			/* button_overlay = */ "back",
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/text/clickable/admin_help(
			null,
			/* hud_owner = */ null,
			/* escape_menu = */ src,
			/* button_text = */ "Создать админ тикет",
			/* offset = */ list(-136, 28),
			/* font_size = */ 24,
			/* on_click_callback = */ CALLBACK(src, PROC_REF(create_ticket)),
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/text/clickable/admin_ticket_notification(
			null,
			/* hud_owner = */ null,
			/* escape_menu = */ src,
			/* button_text = */ "Посмотреть последний тикет",
			/* offset = */ list(-171, 28),
			/* font_size = */ 24,
			/* on_click_callback = */ CALLBACK(src, PROC_REF(view_latest_ticket)),
		)
	)
	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/text/clickable(
			null,
			/* hud_owner = */ null,
			/* escape_menu = */ src,
			/* button_text = */ "Молиться",
			/* offset = */ list(-206, 28),
			/* font_size = */ 24,
			/* on_click_callback = */ CALLBACK(src, PROC_REF(pray)),
		)
	)

	if(CONFIG_GET(flag/see_own_notes))
		page_holder.give_screen_object(
			new /atom/movable/screen/escape_menu/text/clickable(
				null,
				/* hud_owner = */ null,
				/* escape_menu = */ src,
				/* button_text = */ "Просмотреть заметки",
				/* offset = */ list(-241, 28),
				/* font_size = */ 24,
				/* on_click_callback = */ CALLBACK(src, PROC_REF(see_notes)),
			)
		)

/datum/escape_menu/proc/create_ticket()
	if(!(/client/verb/adminhelp in client?.verbs))
		return
	client?.adminhelp()
	qdel(src)

///Opens your latest admin ticket.
/datum/escape_menu/proc/view_latest_ticket()
	client?.view_latest_ticket()

///Manually calls the user's pray() hotkey (which is where prefs is taken into account).
/datum/escape_menu/proc/pray()
	var/datum/keybinding/client/communication/pray/pray_verb = GLOB.keybindings_by_name[/datum/keybinding/client/communication/pray::name]
	pray_verb.down(client)
	qdel(src)

/datum/escape_menu/proc/see_notes()
	if(!CONFIG_GET(flag/see_own_notes))
		to_chat(client.mob, span_notice("Просмотр своих заметок отключен на этом сервере."))
		return
	browse_messages(null, client.ckey, null, TRUE)
	qdel(src)
