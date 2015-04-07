Тест изначально написан Плехановым Дмитрием. Предварительно сделать примерно следующее:

    brew install imagemagick
    sudo gem install rmagick
    sudo gem install method_profiler

Если rmagick не будет билдится, можно поставить предыдущую версию как-то так: `sudo gem install rmagick -v 2.13.3`.

`ruby image_generation_test.rb` -- генерирует шестнадцать html-отчетов по картинкам из /fixtures с использованием функций `extract_colors` и `create_palette`  
`ruby refactoring_test.rb` -- прогоняет image_generation_test и ругается, если хеш-суммы изменились.

Текущая `#expand_palette` бажна и рандомна, поэтому мы не будем класть в `/fixtures` картинки с маленьким набором цветов, пока не перейдем от стадии осторожного рефакторинга к исправлению работы и улучшению библиотеки.
