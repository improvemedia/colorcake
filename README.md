# Colorcake

Find colors and generate palette. So you can show palette and search models by color

## Installation

Add this line to your application's Gemfile:

    gem 'colorcake'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install colorcake

## Usage

1. Run
    rails generate colorcake:install
to install initializer.
2. Add to your model include and method `image_path_for_color_generator`
model should have character field `palette`

      class Photo
        include Colorable

        def image_path_for_color_generator
          image.big.path
        end
      end

## Testing

~~Put images like 0.jpg .. 16.jpg in fixtures and run `rake test` then you should see html files with generated colors and photos~~

То, что автор гема называл тестами, переведено в несколько иную форму -- читать [test/functionals/README.md](test/functionals/README.md)

Так выглядит граф вызовов ф-ций колоркейка с примерными пояснениями:
```
after_create :process_colors : /colorcake/app/models/concerns/colorable.rb
  |
  |  [ a lot of times in marvin ]
  |       |
  v       v
process_colors      : /colorcake/app/models/concerns/colorable.rb
  |                 alias to generate_colors
  |
  |  preview_teaser : /marvin/app/controllers/reports_controller.rb
  |       |         : /marvin/app/controllers/marvin/posts_controller.rb
  v       v
generate_colors     : /colorcake/app/models/concerns/colorable.rb
  |       |         extract_colors[0].each{ colors.create }
  |       |         generate_palette extract_colors[1]
  |       v
  |  extract_colors : /colorcake/lib/colorcake.rb
  |                 return [colors, colors_hex]
  |
generate_palette    : /marvin/app/models/photo.rb
  |                  (/colorcake/app/models/concerns/colorable.rb)
  |                 assign_attributes palette: create_palette(colors), modified_palette: nil
  v
create_palette      : /colorcake/lib/colorcake.rb
                    colors = (slim|expand)_palette colors
```

Таким образом, `image_generation_test.rb`, дергая `generate_colors` и `create_palette` по сути имитирует `generate_colors`, сохраняя палитру (`palette`) и поисковые цвета (`colors`) не в базу, а в html.
