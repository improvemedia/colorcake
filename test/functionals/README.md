Тест изначально написан Плехановым Дмитрием. Чтобы его запускать, была удалена зависимость от гема method_profiler, и в одно место еще в предыдущем коммите добавлен `if defined? Rails`. Также на Mac OS нужно предварительно сделать:

    brew install imagemagick
    sudo gem install rmagick
    sudo gem install method_profiler

Если rmagick не будет билдится, можно поставить предыдущую версию как-то так: `sudo gem install rmagick -v 2.13.3`.

`ruby refactoring_test.rb` -- проверка работы `extract_colors` и `create_palette`

Текущая `expand_palette` бажна и рандомна, поэтому мы не будем насиловать colorcake картинками с маленьким набором цветов, пока не перейдем от стадии осторожного рефакторинга к деструктивному исправлению работы библиотеки.
