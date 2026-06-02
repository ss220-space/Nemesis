/// Макрос для `declent_ru` для автоматической капитализации первой буквы.
#define DECLENT_RU_CAP(target, case_id) capitalize(target.declent_ru(case_id))

/// Преобразует направление в текст на русском языке.
/proc/dir2rustext(direction)
	switch(direction)
		if(NORTH)
			return DIR_NAME_RUS_NORTH
		if(SOUTH)
			return DIR_NAME_RUS_SOUTH
		if(EAST)
			return DIR_NAME_RUS_EAST
		if(WEST)
			return DIR_NAME_RUS_WEST
		if(NORTHEAST)
			return DIR_NAME_RUS_NORTHEAST
		if(SOUTHEAST)
			return DIR_NAME_RUS_SOUTHEAST
		if(NORTHWEST)
			return DIR_NAME_RUS_NORTHWEST
		if(SOUTHWEST)
			return DIR_NAME_RUS_SOUTHWEST
	return NONE

/// Преобразует русский текст в соответствующие направления.
/proc/text2dir_rus(direction)
	switch(direction)
		if(DIR_NAME_RUS_NORTH)
			return NORTH
		if(DIR_NAME_RUS_SOUTH)
			return SOUTH
		if(DIR_NAME_RUS_EAST)
			return EAST
		if(DIR_NAME_RUS_WEST)
			return WEST
		if(DIR_NAME_RUS_NORTHEAST)
			return NORTHEAST
		if(DIR_NAME_RUS_NORTHWEST)
			return NORTHWEST
		if(DIR_NAME_RUS_SOUTHEAST)
			return SOUTHEAST
		if(DIR_NAME_RUS_SOUTHWEST)
			return SOUTHWEST
	return NONE

/**
 * Возвращает список в виде строки на русском языке (с разделителями и "и" перед последним элементом).
 *
 * Пример: `russian_list(list("болт", "гайка", "шайба"))` вернёт `"болт, гайка и шайба"`.
 * С `final_comma_text = ","` вернёт `"болт, гайка, и шайба"`.
 *
 * Аргументы:
 * * `input_list` - Список для преобразования в строку.
 * * `nothing_text` - Текст, возвращаемый для пустого списка.
 * * `and_text` - Текст перед последним элементом.
 * * `comma_text` - Разделитель между элементами.
 * * `final_comma_text` - Разделитель перед последней запятой (заменяет `comma_text` у последней; по умолчанию пусто — без оксфордской запятой).
 */
/proc/russian_list(list/input_list, nothing_text = "ничего", and_text = " и ", comma_text = ", ", final_comma_text = "")
	SHOULD_BE_PURE(TRUE)
	var/list_length = length(input_list)
	if(!list_length)
		return "[nothing_text]"
	if(list_length == 1)
		return "[input_list[1]]"
	if(list_length == 2)
		return "[input_list[1]][and_text][input_list[2]]"
	var/output = ""
	for(var/index in 1 to (list_length - 1))
		var/separator = (index == (list_length - 1)) ? final_comma_text : comma_text
		output += "[input_list[index]][separator]"
	return "[output][and_text][input_list[list_length]]"
