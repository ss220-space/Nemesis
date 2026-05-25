/**
 * Возвращает правильную форму слова, соответствующую русскому склонению числительных.
 *
 * Учитывает правила русского языка, определяющие окончания числительных, на основе переданного числа.
 * Использует три формы: единственное число (1), двойственное число (2-4) и множественное число (5+).
 *
 * Аргументы:
 * * num - Число, для которого необходимо определить форму слова
 * * single_name - Форма слова для 1 (например, "стол")
 * * double_name - Форма слова для 2-4 (например, "стола")
 * * multiple_name - Форма слова для 5+ (например, "столов")
 */
/proc/declension_ru(num, single_name, double_name, multiple_name)
	if(!isnum(num))
		stack_trace("Invalid number argument in declension_ru proc.")
		return double_name
	if(!istext(single_name) || !istext(double_name) || !istext(multiple_name))
		stack_trace("Invalid word arguments in declension_ru proc.")
		return double_name
	if(round(num) != num)
		return double_name // fractional numbers
	if(((num % 10) == 1) && ((num % 100) != 11)) // 1, not 11
		return single_name
	if(((num % 10) in 2 to 4) && !((num % 100) in 12 to 14)) // 2, 3, 4, not 12, 13, 14
		return double_name
	return multiple_name // 5, 6, 7, 8, 9, 0

// Секунд, минут, единиц
#define DECL_SEC_MIN(num) declension_ru(num, "у", "ы", "")
// Кредит, символ
#define DECL_CREDIT(num) declension_ru(num, "", "а", "ов")

/**
 * Возвращает форму слова с учётом грамматического рода в русском языке.
 *
 * Выбирает правильную форму слова в зависимости от его грамматического рода (MALE, FEMALE, NEUTER)
 * или множественного числа (PLURAL). Используется для прилагательных, местоимений и глаголов,
 * изменяющихся по родам.
 *
 * Аргументы:
 * * gender - Грамматический род (MALE, FEMALE, NEUTER, PLURAL)
 * * male_word - Мужская форма (например, "тыкнул")
 * * female_word - Женская форма (например, "тыкнула")
 * * neuter_word - Средняя форма (например, "тыкнуло")
 * * multiple_word - Форма множественного числа (например, "тыкнули")
 */
/proc/genderize_ru(gender, male_word, female_word, neuter_word, multiple_word)
	if(!(gender in list(MALE, FEMALE, NEUTER, PLURAL)))
		stack_trace("Invalid gender argument in genderize_ru proc.")
		return multiple_word
	if(!istext(male_word) || !istext(female_word) || !istext(neuter_word) || !istext(multiple_word))
		stack_trace("Invalid word arguments in genderize_ru proc.")
		return multiple_word
	return gender == MALE ? male_word : (gender == FEMALE ? female_word : (gender == NEUTER ? neuter_word : multiple_word))

// Местоимения.
#define GEND_HE_SHE(target) genderize_ru(target.gender, "он", "она", "оно", "они")
#define GEND_HE_SHE_CAP(target) capitalize(genderize_ru(target.gender, "он", "она", "оно", "они"))
#define GEND_HIS_HER(target) genderize_ru(target.gender, "его", "её", "его", "их")
#define GEND_HIS_HER_CAP(target) capitalize(genderize_ru(target.gender, "его", "её", "его", "их"))
#define GEND_HIM_HER(target) genderize_ru(target.gender, "ему", "ей", "ему", "им")
#define GEND_ON_IN_HIM(target) genderize_ru(target.gender, "нём", "ней", "нём", "них")
#define GEND_YOUR(target) genderize_ru(target.gender, "ваш", "вашу", "ваше", "ваши")
#define GEND_YOURS(target) genderize_ru(target.gender, "вашего", "вашей", "вашего", "ваших")
// Окончания. Y — буква Ы.
#define GEND_A_O_I(target) genderize_ru(target.gender, "", "а", "о", "и")
#define GEND_A_O_Y(target) genderize_ru(target.gender, "", "а", "о", "ы")
#define GEND_A_E_I(target) genderize_ru(target.gender, "", "а", "е", "и")
#define GEND_SYA_AS_OS_IS(target) genderize_ru(target.gender, "ся", "ась", "ось", "ись")
#define GEND_LA_LO_LI(target) genderize_ru(target.gender, "", "ла", "ло", "ли")
#define GEND_EN_NA_NO_NY(target) genderize_ru(target.gender, "ен", "на", "но", "ны")
#define GEND_EM_EI_EM_IH(target) genderize_ru(target.gender, "ем", "ей", "ем", "их")
#define GEND_YM_OI_YM_YMI(target) genderize_ru(target.gender, "ым", "ой", "ым", "ыми")
#define GEND_IM_EI_IM_IMI(target) genderize_ru(target.gender, "им", "ей", "им", "ими")
#define GEND_YI_AYA_OE_YE(target) genderize_ru(target.gender, "ый", "ая", "ое", "ые")
#define GEND_II_AYA_II_IE(target) genderize_ru(target.gender, "ий", "ая", "ий", "ие")
// Макросы для случаев, когда обычные не применимы.
#define GEND_SHEL(target) genderize_ru(target.gender, "шёл", "шла", "шло", "шли")

/**
 * Возвращает форму единственного или множественного числа в зависимости от грамматического рода.
 *
 * Простой инструмент, который помогает легко переключаться между формами единственного и
 * множественного числа, основываясь на указанном роде.
 *
 * Аргументы:
 * * gender - Грамматический род (MALE, FEMALE, NEUTER, PLURAL)
 * * single_word - Форма единственного числа (например, "делает")
 * * plural_word - Форма множественного числа (например, "делают")
 */
/proc/pluralize_ru(gender, single_word, plural_word)
	return gender == PLURAL ? plural_word : single_word

#define PLUR_ET_YUT(target) pluralize_ru(target.gender, "ет", "ют")
#define PLUR_YOT_YUT(target) pluralize_ru(target.gender, "ёт", "ют")
#define PLUR_ET_UT(target) pluralize_ru(target.gender, "ет", "ут")
#define PLUR_YOT_UT(target) pluralize_ru(target.gender, "ёт", "ут")
#define PLUR_IT_YAT(target) pluralize_ru(target.gender, "ит", "ят")
#define PLUR_IT_AT(target) pluralize_ru(target.gender, "ит", "ат")
#define PLUR_I(target) pluralize_ru(target.gender, "", "и")
// Макросы для случаев, когда обычные не применимы.
#define PLUR_JET_GUT(target) pluralize_ru(target.gender, "жет", "гут")
#define PLUR_CHET_TYAT(target) pluralize_ru(target.gender, "чет", "тят")

/**
 * Обрабатывает гендерно-зависимую текстовую разметку в строке.
 *
 * Заменяет шаблоны %(SINGLE,PLURAL)% и %(MALE,FEMALE,NEUTER,PLURAL)% в сообщении
 * на соответствующую форму слова в зависимости от пола моба.
 * Используйте * для пропуска конкретной формы рода (например, %(*,FEMALE,*,PLURAL)%).
 * Обрабатывает все шаблоны до тех пор, пока они полностью не исчезнут.
 *
 * Аргументы:
 * * user - Моб, чей пол определяет форму слов (использует NEUTER, если не моб)
 * * msg - Строка с гендерной разметкой для обработки
 */
/proc/genderize_decode(mob/user, msg)
	if(!istext(msg))
		stack_trace("Invalid arguments in genderize_decode proc.")
	var/gender
	if(ismob(user))
		gender = user.gender
	else
		gender = NEUTER
	while(TRUE)
		var/prefix = findtext_char(msg, "%(")
		if(!prefix)
			break
		var/postfix = findtext_char(msg, ")%")
		if(!postfix)
			stack_trace("Genderize string is missing proper ending, expected )%.")
			break
		var/list/pieces = splittext(copytext_char(msg, prefix + 2, postfix), ",")
		switch(length(pieces))
			if(2) // pluralize if only two parts present
				msg = replacetext(splicetext_char(msg, prefix, postfix + 2, pluralize_ru(gender, pieces[1], pieces[2])), "*", "")
			if(4) // use full genderize if all four parts exist
				msg = replacetext(splicetext_char(msg, prefix, postfix + 2, genderize_ru(gender, pieces[1], pieces[2], pieces[3], pieces[4])), "*", "")
			else
				stack_trace("Invalid data sent to genderize_decode proc.")
	return msg

/// Макрос для `declent_ru` для автоматической капитализации первой буквы
#define DECLENT_RU_CAP(target, case_id) capitalize(target.declent_ru(case_id))

// Names for directions (Russian)
#define DIR_NAME_RUS_NORTH "север"
#define DIR_NAME_RUS_SOUTH "юг"
#define DIR_NAME_RUS_EAST "восток"
#define DIR_NAME_RUS_WEST "запад"
#define DIR_NAME_RUS_NORTHEAST "северо-восток"
#define DIR_NAME_RUS_SOUTHEAST "юго-восток"
#define DIR_NAME_RUS_NORTHWEST "северо-запад"
#define DIR_NAME_RUS_SOUTHWEST "юго-запад"

/// Turns a direction into ru text
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

/// Turns russian text into proper directions
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
 * Returns a list in plain russian as a string
 *
 * Arguments:
 * * input_list - The list to convert to a string
 * * nothing_text - Text to return if the list is empty
 * * and_text - Text to use before the last item
 * * comma_text - Text to use between items
 * * final_comma_text - Text to use before the last item (replaces comma_text for the last comma)
 */
/proc/russian_list(list/input_list, nothing_text = "ничего", and_text = " и ", comma_text = ", ", final_comma_text = "" )
	var/list_length = length(input_list)
	if(!list_length)
		return "[nothing_text]"
	else if(list_length == 1)
		return "[input_list[1]]"
	else if(list_length == 2)
		return "[input_list[1]][and_text][input_list[2]]"
	else
		var/output = ""
		var/current_index = 1
		while(current_index < list_length)
			if(current_index == list_length - 1)
				comma_text = final_comma_text

			output += "[input_list[current_index]][comma_text]"
			current_index++

		return "[output][and_text][input_list[current_index]]"
