
module Closets
  @svgResult
  @max = 800
  @nextH
  @x
  @y

  def self.renderSvg
    @svgResult = ""
    @nextH = 0
    @x = 0
    @y = 0
    renderHeader
    renderSheet
    renderParts
    renderFooter
    outputSvg
  end

  def self.renderHeader
    @svgResult +=  "<?xml version=\"1.0\" standalone=\"no\"?>\n
     <svg version=\"1.1\"
     baseProfile=\"full\"
     width=\"#{@max}\" height=\"400%\"
     xmlns=\"http://www.w3.org/2000/svg\">"
  end

  def self.renderSheet
    width   = toSvgLength(96)
    height  = toSvgLength(48)
    nextW   = toSvgLength(@@parts[1][3])
    @svgResult += "<rect x=\"#{@x}\" y=\"#{@y}\" width=\"#{width}\" height=\"#{height}\" stroke=\"black\" fill=\"rgb(96, 167, 193)\"/>\n"
    @svgResult += ""
    puts "width:#{width} nextW:#{nextW}" # << NEXTW NEEDS TO SKIP UN-SVGABLE PARTS/NAMES!
    setSvgCoords(width, height, nextW)
  end

  def self.renderParts
    @@parts.each_with_index do |part, i|
      name    = part[0]
      qty     = part[1]
      height  = toSvgLength(part[2])
      width   = toSvgLength(part[3])
      if (["Shelf", "Gable", "Cleat"].include? name)
        qty.times do |k|
          @svgResult += "<rect x=\"#{@x}\" y=\"#{@y}\" width=\"#{width}\" height=\"#{height}\" stroke=\"black\" fill=\"rgb(126, 188, 153)\" />\n"
          nextW = (k == qty-1 && i < @@parts.length) ? toSvgLength(@@parts[i+1][3]) : width
          @svgResult += "<text x=\"#{@x+10}\" y=\"#{@y+20}\">width = #{width} nextW = #{nextW}</text>\n"
          setSvgCoords(width, height, nextW)
        end
      end
    end
  end

  def self.renderFooter
    @svgResult += "</svg>"
  end

  def self.setSvgCoords(width, height, nextW = 0)
    @nextH = height if (height > @nextH)
    if ((@x + width + nextW) <= @max)

      @x += width
    else
      @x = 0
      @y += @nextH
      @nextH = 0
    end
  end

  def self.outputSvg
    filename = UI.savepanel("Save Cut List", Dir::pwd, 'SVG file|*.svg||')
    return unless filename
    filename << ".svg" unless filename[-4..-1] == ".svg"

    f = File.new(filename, 'w')
    f.write(@svgResult)
    f.close
  end

  def self.toSvgLength(length)
    (length.to_f/12*100).round
  end

end # Closets
