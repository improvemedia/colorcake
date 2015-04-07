require_relative 'colorcake/version'
require_relative 'colorcake/color_util'
require_relative 'colorcake/merge_colors_methods'

require 'RMagick'

module Colorcake
  require 'colorcake/engine' if defined? Rails

  class << self
    attr_accessor :base_colors, :colors_count,
      :max_numbers_of_color_in_palette,
      :white_threshold, :black_threshold,
      :delta, :cluster_colors, :color_aliases

    def configure &blk
      class_eval &blk
      @base_colors ||= %w{ 660000 cc0000 ea4c88 993399 663399 304961 0066cc 66cccc 77cc33 336600 cccc33 ffcc33 fff533 ff6600 c8ad7f 996633 663300 000000 999999 cccccc ffffff }
      @cluster_colors ||= {
        '660000' => '660000',
        'cc0000' => 'cc0000', 'ce454c' => 'cc0000',
        'ea4c88' => 'ea4c88',
        '993399' => '993399',
        '663399' => '663399',
        '304961' => '304961', '405672' => '304961',
        '0066cc' => '0066cc', '1a3672' => '0066cc', '333399' => '0066cc', '0099cc' => '0066cc',
        '66cccc' => '66cccc',
        '77cc33' => '77cc33',
        '336600' => '336600',
        'cccc33' => 'cccc33', '999900' => 'cccc33',
        'ffcc33' => 'ffcc33',
        'fff533' => 'fff533', 'efd848' => 'fff533',
        'ff6600' => 'ff6600',
        'c8ad7f' => 'c8ad7f', 'ccad37' => 'c8ad7f', 'e0d3ba' => 'c8ad7f',
        '996633' => '996633',
        '663300' => '663300',
        '000000' => '000000', '2e2929' => '000000',
        '999999' => '999999', '7e8896' => '999999', '636363' => '999999',
        'cccccc' => 'cccccc', 'afb5ab' => 'cccccc',
        'ffffff' => 'ffffff', 'dde2e2' => 'ffffff', 'edefeb' => 'ffffff', 'ffe6e6' => '',  'ffe6e6' => 'ffffff', 'd5ccc3' => 'ffffff',
        'f6fce3' => 'ffffff',
        'e1f4fa' => 'ffffff',
        'e5e1fa' => 'ffffff',
        'fbe2f1' => 'ffffff',
        'fffae6' => 'ffffff',
        'ede7cf' => 'ffffff',
        'cae0e7' => 'ffffff',
        'ede1cf' => 'ffffff',
        'cae0e7' => 'ffffff',
        'cad3d5' => 'ffffff'
      }

      @color_aliases ||= {
        "660000" => 'maroon',
        "cc0000" => 'red',
        "ea4c88" => 'pink',
        "993399" => 'magenta',
        "663399" => 'violet',
        "304961" => 'blue',
        "0066cc" => 'lightblue',
        "66cccc" => 'greenyellow',
        "77cc33" => 'green',
        "336600" => 'goldenrod',
        "cccc33" => 'gold',
        "ffcc33" => 'lightyellow',
        "fff533" => 'yellow',
        "ff6600" => 'orange',
        "c8ad7f" => 'beige',
        "996633" => 'peru',
        "663300" => 'brown',
        "000000" => 'black',
        "999999" => 'gray',
        "cccccc" => 'lightgray',
        "ffffff" => 'white'
      }

      @colors_count ||= 60
      @max_numbers_of_color_in_palette ||= 5
      @white_threshold ||= 55_000
      @black_threshold ||= 2000
      @delta ||= 2.5
    end
  end

  def self.extract_colors src
    colors = {}
    colors_hex = {}
    palette = compute_palette(src)

    sum_of_pixels = palette.values.inject(:+)
    palette.each do |k, v|
      palette[k] = [v, v / (sum_of_pixels.to_f / 100)]
    end

    old_palette = palette

    new_palette = palette.map.with_index do |(color1, n1), index|
      common_colors = []
      if index < palette.length
        palette.each do |color2, n2|
          sr = color1.red
          sb = color1.blue
          sg = color1.green
          cr = color2.red
          cb = color2.blue
          cg = color2.green
          sr = color1.red / 257 if color1.red / 255 > 0
          sb = color1.blue / 257 if color1.blue / 255 > 0
          sg = color1.green / 257 if color1.green / 255 > 0
          cr = color2.red / 257 if color2.red / 255 > 0
          cb = color2.blue / 257 if color2.blue / 255 > 0
          cg = color2.green / 257 if color2.green / 255 > 0
          delta =  ColorUtil.delta_e(ColorUtil.rgb_to_lab([sr, sb, sg]),
                                     ColorUtil.rgb_to_lab([cr, cb, cg]))
          if delta < @delta
            common_colors << [color2, n2]
            common_colors << [color1, n1]
            common_colors.uniq!

            if common_colors.first[1][1] && common_colors.first[1][1] != n2[1]
              common_colors.first[1][1] += n2[1]
            elsif common_colors.first[1][1] == n2[1]
              common_colors.first[1][1] = n2[1]
            end
          end
        end
        common_colors.uniq!
        common_colors.each_with_index do |col, ind|
          if ind != 0
            old_palette.delete col[0]
          end
        end
        common_colors.first
      end
    end

    new_palette.each do |i|
      c = i[0].to_s.split(',').map{ |x| x[/\d+/] }
      b = compute_b(c)
      closest_color = closest_color_to(b)
      percentage = i[1][1]
      colors_hex['#' + c.join] = i[1]

      id = if defined? Rails
        SearchColor.find_or_create_by_color(closest_color[0]).id
      else
        @base_colors.index closest_color[0]
      end

      colors[id] ||= {}
      colors[id][:search_color_id] ||= id
      colors[id][:search_factor] ||= []
      colors[id][:search_factor] << percentage
      colors[id][:distance] ||= []
      colors[id][:hex] ||= c.join
      colors[id][:original_color] ||= []
      colors[id][:original_color] << {('#' + c.join) => i[1]}
      colors[id][:hex_of_base] ||= @base_colors[id] if id
      colors[id][:distance] = closest_color[1] if colors[id][:distance] == []
    end

    colors.each_with_index do |fac, index|
      # Algorithm defines color preferabbility amongst others
      # (for now it is only sum of place percentage)
      colors[fac[0]][:search_factor] = fac[1][:search_factor].reduce(:+).to_i
    end

    # Disable when not working with DB
    # [colors, colors_hex]
    colors.delete_if{ |k,| colors[k][:search_factor] < 1 }
    [colors, colors_hex]
  end

  def self.create_palette colors
    if colors.length > @max_numbers_of_color_in_palette
      colors = slim_palette colors
      create_palette colors
    elsif colors.length == @max_numbers_of_color_in_palette
      return colors
    else
      colors = expand_palette colors
      create_palette colors
    end
  end

  private

  def self.compute_b c
    c.pop
    c[0], c[1], c[2] = [c[0], c[1], c[2]].map do |s|
      s = s.to_i
      s = s / 257 if s / 255 > 0 # not all ImageMagicks are created equal....
      s = s.to_s(16)
      if s.size == 1
        '0' + s
      else
        s
      end
    end
    c.join.scan(/../).map{ |color| color.to_i 16 }
  end

  def self.closest_color_to b
    # do not remove, used in /marvin/lib/tasks/colors.rake
    closest_colors = {}
    @cluster_colors.each_key do |extended_color, |
      closest_colors[extended_color] = ColorUtil.delta_e(
        ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(extended_color)),
        ColorUtil.rgb_to_lab(b)
      )
    end
    closest_color = closest_colors.min_by{ |a, d| d }
    if cluster = @cluster_colors[closest_color[0]]
      closest_color = [
        cluster,
        ColorUtil.delta_e(
          ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(cluster)),
          ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(closest_color[0]))
        )
      ]
    end
    closest_color
  end

  def self.compute_palette src
    image = ::Magick::ImageList.new(src)
    image_quantized = image.quantize(@colors_count, Magick::YIQColorspace)
    palette = image_quantized.color_histogram # {#<Magick::Pixel:0x007fc19a08fd00>=>61660, ...}
    image_quantized.destroy!
    image.destroy!
    palette
  end

  def self.expand_palette colors
    col_array = colors.to_a
    rgb_color_1 = ColorUtil.rgb_from_string(col_array[0][0])
    rgb_color_2 = ColorUtil.rgb_from_string(col_array[-1][0])
    if col_array.length == 1
      rgb_color_2 = [
        rgb_color_1[0] + rand(0..10),
        rgb_color_1[1] + rand(0..20),
        rgb_color_1[2] + rand(0..30),
      ]
    end
    rgb = [
      (rgb_color_1[0] + rgb_color_2[0]) / 2,
      (rgb_color_1[1] + rgb_color_2[1]) / 2,
      (rgb_color_1[2] + rgb_color_2[2]) / 2,
    ]
    rgb.map!{ |c| c.to_i.to_s 16 }
    colors.merge!( { '#' + rgb.join => [1, 2] } )
  end

  def self.slim_palette colors
    col_array = colors.to_a
    matrix = col_array.map do |row|
      col_array.map do |col|
        rgb_color_1 = ColorUtil.rgb_from_string(row[0])
        rgb_color_2 = ColorUtil.rgb_from_string(col[0])
        pixel_1 = ColorUtil.rgb_to_lab([rgb_color_1[0], rgb_color_1[1], rgb_color_1[2]])
        pixel_2 = ColorUtil.rgb_to_lab([rgb_color_2[0], rgb_color_2[1], rgb_color_2[2]])
        diff = ColorUtil.delta_e(pixel_1, pixel_2)
        # c1 = ColorUtil.rgb_to_hcl(rgb_color_1[0],rgb_color_1[1],rgb_color_1[2])
        # c2 = ColorUtil.rgb_to_hcl(rgb_color_2[0],rgb_color_2[1],rgb_color_2[2])
        # diff = ColorUtil.distance_hcl(c1, c2)
        diff == 0 ? 100_000 : diff
      end
    end
    colors_position = find_position_in_matrix_of_closest_color(matrix)
    closest_colors = [colors.to_a[colors_position[0]], colors.to_a[colors_position[1]]]
    merge_result = MergeColorsMethods.lab_merge(closest_colors)
    colors.merge!(merge_result[0])
    colors.delete(merge_result[1])
    colors
  end

  def self.find_position_in_matrix_of_closest_color matrix
    matrix_array = matrix.to_a
    minimum = matrix_array.flatten.min
    i = matrix_array.index{ |x| x.include? minimum }
    [i, matrix_array[i].index(minimum)]
  end

end
