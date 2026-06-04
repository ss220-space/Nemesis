<!--Номера PR'ов-->

https://github.com/ss220-space/Nemesis/pull/98
https://github.com/ss220-space/Nemesis/pull/100
https://github.com/ss220-space/Nemesis/pull/107

## Модуль локализации

Module ID: LOCALIZATION

### Описание:

- Предоставляет проки для работы с локализацией.
- Заменяет ТГ шрифты на шрифты с поддержкой кириллицы.

<!-- Здесь опишите, что делает ваш PR, какие фичи он добавляет и любую другую напрямую полезную информацию. -->

### Изменения в TG-проках/файлах:

- `interface/fonts/grand9k.dm`: `var/font_family`
- `interface/fonts/pixellari.dm`: `var/font_family`
- `interface/fonts/spess_font.dm`: `var/font_family`
- `interface/fonts/tiny_unicode.dm`: `var/font_family`
<!-- Если вы редактировали какие-либо проки в основном коде, перечислите их здесь. Указывайте файлы и процедуры, которые вы изменили.
Например:
- `code/modules/mob/living.dm`: `proc/overriden_proc`, `var/overriden_var`
  -->

### Модульные override'ы:

- N/A
<!-- Если вы добавили новый модульный override (файл или код) для своего модуля — перечислите его здесь. Для файлов с кодом указывайте, какие процедуры они меняют, на случай если несколько модулей используют один и тот же файл.
Например:
- `modular_nemesis/master_files/sound/my_cool_sound.ogg`
- `modular_nemesis/master_files/code/my_modular_override.dm`: `proc/overriden_proc`, `var/overriden_var`
  -->

### Define'ы:

- `code/__DEFINES/~nemesis_defines/localization`
- `code/__HELPERS/~nemesis_helpers/localization`
- `code/_globalvars/~nemesis_globalvars/localization`
<!-- Если вам пришлось добавить какие-либо define'ы, упомяните файлы, в которые вы их добавили, а также названия самих define'ов. -->

### Подключаемые файлы, не входящие в этот модуль:

- N/A
<!-- Аналогично — будь то немодульный файл или модульный файл, не находящийся в папке, принадлежащей именно этому модулю, его следует упомянуть здесь. Хорошие примеры — иконки или звуки, используемые сразу несколькими модулями, и тому подобные пограничные случаи. -->

### Авторы:

Руководство по локализации и проки:
https://github.com/littleboobs
https://github.com/PlayerUnknown14

Адаптация шрифтов SpessFont и TinyUnicode для кириллицы:
https://github.com/ss220club/BandaStation/pull/776

<!-- Здесь идут благодарности вам, дорогой кодер, а в случае совместной работы или портов — указание на оригинальный источник кода. -->
