require_relative '../../lib/colorcake'

Colorcake.configure do
  # taken from /marvin/config/initializers/colorcake.rb
  @base_colors ||= %w{ 660000 cc0000 ea4c88 993399 663399 304961 0066cc 66cccc 77cc33 336600 cccc33 ffcc33 fff533 ff6600 c8ad7f 996633 663300 000000 999999 cccccc ffffff }
end

STDOUT.sync = true

(
  ARGV.empty? ? 0..15 : [ARGV.first]
).map do |i|
  Thread.new do
    index = i
    # puts "<< #{index}"

    html = ""

    found_colors = Colorcake.extract_colors File.join(__dir__, "fixtures", "#{index}.jpg")

    found_colors[1].each do |color, percentage|
      html << "<div style='background: #{color}'></div>"
    end
    html << "<h1 style='clear:both'>Search Colors</h1>"

    found_colors[0].each do |color|
      html << if color[1][:hex_of_base] == "ffffff"
        "<div style='background: ##{color[1][:hex_of_base]};color:#333; border:1px solid red'>#{color[1][:search_factor]}</div>"
      else
        "<div style='background: ##{color[1][:hex_of_base]};color:#fff;' >  #{color[1][:search_factor]} </div>"
      end
    end

    html << "<h1 style='clear:both'>Palette Colors(original 5 most contrast and colorful colors)</h1>"
    Colorcake.create_palette(found_colors[1]).sort_by{ |x| - x[1][1] }.each do |color, percentage|
      html << "<div style='background: #{color};color:#fff;'  >  #{percentage[1].round(2)} </div>"
    end

    puts [$AAA, $BBB, $CCC, $DDD].inspect if ENV["DEBUG"]

    File.open(File.join("fixtures", "photo#{index}.html"), "w") do |f|
      f.write "<html><head><style>"\
                 "h1{font-size:16px}"\
                 "#colors{float:left; width: 50%}"\
                 "*{box-sizing:border-box}"\
                 "div{float:left;width:70px;height:70px;line-height:70px; text-align:center; font-weight:bold; font-family: Helvetica, Arial}"\
               "</style></head>"\
               "<body><div id=\"colors\"><h1 style='clear:both'>Original Colors</h1>" +
                 html + "</div><div id='image'><img style='display:block; clear:both' src='#{index}.jpg'/></div>"\
               "</body></html>"
    end

    # puts ">> #{index}"
  end
end.map(&:join)
