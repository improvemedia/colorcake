require_relative 'colorcake/version'
require_relative 'colorcake/color_util'
require_relative 'colorcake/merge_colors_methods'

require 'rmagick'

module Colorcake
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
        'ffffff' => 'ffffff', 'dde2e2' => 'ffffff', 'edefeb' => 'ffffff', 'ffe6e6' => 'ffffff', 'd5ccc3' => 'ffffff',
        'f6fce3' => 'ffffff',
        'e1f4fa' => 'ffffff',
        'e5e1fa' => 'ffffff',
        'fbe2f1' => 'ffffff',
        'fffae6' => 'ffffff',
        'ede7cf' => 'ffffff',
        'cae0e7' => 'ffffff',
        'ede1cf' => 'ffffff',
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

  def self.extract_colors src, search_factor: 2
    colors = {}
    colors_hex = {}

    palette = _generate_palette(src)

    common_colors = _generate_common_colors_from_palette(palette)

    common_colors.each do |color, n|
      c = color.to_s.split(",").take(3).map do |s|
        s = s[/\d+/].to_i
        s = s / 257 if s / 255 > 0 # not all ImageMagicks are created equal....
        s
      end

      closest_color, delta = closest_color_to c
      hex_color = c.pack("C*").unpack("H*")[0] # [0,100,255].pack("C*").unpack("H*") => ["0064ff"]
      colors_hex[hex_color] = n

      id = closest_color

      colors[id] ||= {}
      colors[id][:search_factor] ||= []
      colors[id][:search_factor] << n[1]
      colors[id][:distance] ||= []
      colors[id][:closest_color] ||= closest_color
      colors[id][:hex] ||= hex_color
      colors[id][:original_color] ||= []
      colors[id][:original_color] << {"#" + hex_color => n}
      colors[id][:distance] = delta if colors[id][:distance] == []
    end

    colors.each_with_index do |fac, index|
      # Algorithm defines color preferabbility amongst others
      # (for now it is only sum of place percentage)
      colors[fac[0]][:search_factor] = fac[1][:search_factor].reduce(:+).to_i
    end

    # Disable when not working with DB
    # [colors, colors_hex]
    colors.delete_if{ |k,| colors[k][:search_factor] < search_factor }

    #sort by appearing in the picture
    palette  = Colorcake.create_palette(colors_hex)
    bg_color = palette.sort_by { |r| r.last.last }.last.first

    {
      recommended_colors: colors.keys,
      palette: palette.keys,
      bg_color: bg_color
    }
  end

  def self.create_palette colors
    # raise "gonna crash with 'too deep stack level'" if caller.size > 5000 if ((Time.now.to_f.round(3)*1000) % 10) == 0
    d = @max_numbers_of_color_in_palette - colors.length

    return colors if d.zero?

    col_array = colors.to_a

    if d < 0

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

    else

      rgb = ColorUtil.rgb_from_string(col_array.sample[0])
      preferable_shifts = (-rgb.min..255-rgb.max).sort_by{ |shift| [
        shift.abs < 30        ? [2, -shift.abs] :
        (shift.abs % 30) != 0 ? [1,  shift.abs] :
                                [0,  shift.abs]
      ] }
      preferable_shifts.take(d).each do |shift|
        imaginable_color = rgb.map{ |channel| channel + shift }
        colors.merge! ("#" + imaginable_color.pack("C*").unpack("H*")[0]) => [1, 2]
      end

    end

    create_palette colors
  end

  private

  def self._generate_palette(image_url)
    image = ::Magick::ImageList.new(image_url)
    image_quantized = image.quantize(@colors_count, Magick::YIQColorspace)
    palette = image_quantized.color_histogram # {#<Magick::Pixel:0x007fc19a08fd00>=>61660, ...}
    image_quantized.destroy!
    image.destroy!
    sum_of_pixels = palette.values.inject(:+)

    palette.each do |k, v|
      palette[k] = [v, v / (sum_of_pixels / 100.0)]
    end
  end

  def self._generate_common_colors_from_palette(palette)
    palette.map.with_index do |(color1, n1), index|
      raise "Unexpected for algorithm: index < palette.length" unless index < palette.length
      common_colors = []
      r1 = color1.red
      b1 = color1.blue
      g1 = color1.green
      r1 /= 257 if r1 / 255 > 0
      b1 /= 257 if b1 / 255 > 0
      g1 /= 257 if g1 / 255 > 0
      lab = ColorUtil.rgb_to_lab([r1, b1, g1])
      palette.each do |color2, n2|
        r2 = color2.red
        b2 = color2.blue
        g2 = color2.green
        r2 /= 257 if r2 / 255 > 0
        b2 /= 257 if b2 / 255 > 0
        g2 /= 257 if g2 / 255 > 0
        next unless @delta > ColorUtil.delta_e(lab, ColorUtil.rgb_to_lab([r2, b2, g2]))
        common_colors << [color2, n2]
        common_colors << [color1, n1]
        common_colors.uniq!
        if common_colors.first[1][1] && common_colors.first[1][1] != n2[1]
          common_colors.first[1][1] += n2[1]
        end
      end
      common_colors.uniq!
      common_colors.drop(1).each do |col|
        palette.delete col[0]
      end
      common_colors.first
    end
  end

  def self._search_color_id(color)
    @base_colors.index color
  end

  def self.closest_color_to b
    # do not remove, used in /marvin/lib/tasks/colors.rake
    lab = ColorUtil.rgb_to_lab(b)
    closest_color = @cluster_colors.keys.min_by do |extended_color|
      ColorUtil.delta_e(
        ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(extended_color)),
        lab
      )
    end
    cluster = @cluster_colors[closest_color]
    [
      cluster,
      ColorUtil.delta_e(
        ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(cluster)),
        ColorUtil.rgb_to_lab(ColorUtil.rgb_number_from_string(closest_color))
      )
    ]
  end

  def self.find_position_in_matrix_of_closest_color matrix
    flattened = matrix.flatten
    i = flattened.index flattened.compact.min
    [i / matrix.size, i % matrix.size]
  end

end
