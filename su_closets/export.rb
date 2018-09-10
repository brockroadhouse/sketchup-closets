require "csv"

module Closets

  @@comps
  @@csv
  @@cost = 0.09
  @@drawer = 77.5

  def self.exportCutList
    startOperation("Export", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    @@comps = Hash.new
    @@selection.each do |s|
      getSelectionComps(s)
    end

    setOutput
    export

    endOperation
  end # export

  def self.setOutput
    @@csv = Array.new
    @@comps.each do |guid, comp|
      name = comp[:instance].name
      inst = comp[:instance].bounds
      c = comp[:count]
      w = inst.width
      h = inst.height
      d = inst.depth

      if (name.include? "Gable")
        @@csv << ["Gable", c, h, d, w, "$"+@@cost.to_s, sprintf("$%2.2f", c*h*d*@@cost)]
      elsif (name.include? "Shelf")
        @@csv << ["Shelf", c, w, h, d, "$"+@@cost.to_s, sprintf("$%2.2f", c*w*h*@@cost)]
      elsif (name.include? "Cleat")
        @@csv << ["Cleat", c, w, d, h, "$"+@@cost.to_s, sprintf("$%2.2f", c*w*d*@@cost)]
      elsif (name.include? "Drawer")
        @@csv << ["Drawer", c, w, d, h, "$"+@@cost.to_s, sprintf("$%2.2f", c*w*d*@@cost+@@drawer*c)]
      end
    end
    @@csv.sort!
  end

  def self.getSelectionComps(s)
    if (s.is_a? Sketchup::ComponentInstance)
      guid = s.definition.guid
      if (@@comps.has_key? guid)
        @@comps[guid][:count] = @@comps[guid][:count]+1
      else
        @@comps[guid] = {:count => 1, :instance => s.definition}
      end
    elsif (s.is_a? Sketchup::Group)
      s.entities.each { |g| getSelectionComps(g) }
    end
  end

  def self.export
    filename = UI.savepanel("Save Cut List", Dir::pwd, @@model.title+".csv")
    return unless filename
    CSV.open(filename, "wb") do |file|
      file << ["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"]
      @@csv.each do |line|
        file << line
      end
    end
    UI.messagebox("Exported to "+filename)
  end


end # Module
