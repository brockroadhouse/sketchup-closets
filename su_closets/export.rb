require "csv"
require "su_closets/svg.rb"

module Closets

  @@comps
  @@parts
  @@cost = 0.09
  @@rodCost = 0.5
  @@railCost = 1
  @@drawerCost = 77.5
  @@total = 0

  def self.exportCutList
    startOperation("Export Cut List", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
    exportCsv

    endOperation
  end # export

  def self.exportSvg
    startOperation("Export SVG", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
    renderSvg

    endOperation
  end

  def self.setParts
    @@total = 0
    @@comps = Hash.new
    @@selection.each do |s|
      getSelectionComps(s)
    end
    setPartsList
  end

  def self.setPartsList
    @@parts = Array.new
    @@comps.each do |group, components|
      closetTotal = 0
      @@parts << [group]
      components.each do |guid, comp|
        name = comp[:instance].name
        inst = comp[:instance].bounds
        c = comp[:count]
        w = inst.width
        h = inst.height
        d = inst.depth
        cost = 0

        if (name.include? "Gable")
          cost = c*h.to_f*d.to_f*@@cost
          @@parts << ["Gable", c, h, d, w, "$"+@@cost.to_s, sprintf("$%2.2f", cost)]
        elsif (name.include? "Shelf")
          cost = c*w.to_f*h.to_f*@@cost
          @@parts << ["Shelf", c, w.to_l, h.to_l, d, "$"+@@cost.to_s, sprintf("$%2.2f", cost)]
        elsif (name.include? "Cleat")
          cost = c*w.to_f*d.to_f*@@cost
          @@parts << ["Cleat", c, w, d, h, "$"+@@cost.to_s, sprintf("$%2.2f", cost)]
        elsif (name.include? "Door")
          cost = c*w.to_f*d.to_f*@@cost
          @@parts << ["Door", c, w, d, h, "$"+@@cost.to_s, sprintf("$%2.2f", cost)]
        elsif (name.include? "Drawer")
          rate = (w.to_f*d.to_f*@@cost+@@drawerCost)
          cost = c*rate
          @@parts << ["Drawer", c, w, d, h,sprintf("$%2.2f",rate), sprintf("$%2.2f", cost)]
        elsif (name.include? "Rod")
          cost = c*w.to_f*@@rodCost
          @@parts << ["Rod", c, w, '1"', '1.5"', sprintf("$%2.2f", @@rodCost), sprintf("$%2.2f", cost)]
        elsif (name.include? "Rail")
          cost = c*w.to_f*@@railCost
          @@parts << ["Wall Rail", c, w, '1"', '1"', sprintf("$%2.2f", @@railCost), sprintf("$%2.2f", cost)]
        end
        closetTotal += cost
      end
      @@parts << ["", "", "", "", "", "SubTotal", sprintf("$%2.2f", closetTotal)]
      @@parts << [""]
      @@total += closetTotal
    end
  end # setPartsList

  def self.getSelectionComps(s, name = nil)
    if (s.is_a? Sketchup::ComponentInstance)
      guid = s.definition.guid
      @@comps[name] = Hash.new unless (@@comps.has_key? name)
      if (@@comps[name].has_key? guid)
        @@comps[name][guid][:count] = @@comps[name][guid][:count]+1
      else
        @@comps[name][guid] = {:count => 1, :instance => s.definition}
      end
    elsif (s.is_a? Sketchup::Group)
      gName = (name == nil) ? s.name : name
      s.entities.each { |g| getSelectionComps(g, gName) }
    end
  end

  def self.exportCsv
    title = @@model.title.length > 0 ? @@model.title : "Cut List"
    filename = UI.savepanel("Save Cut List", Dir::pwd, 'CSV file|*.csv||')
    return unless filename
    filename << ".csv" unless filename[-4..-1] == ".csv"

    begin
      CSV.open(filename, "wb") do |file|
        file << ["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"]
        @@parts.each do |line|
          file << line
        end
        file << ["", "", "", "", "", "Total:", sprintf("$%2.2f", @@total)]
      end
    rescue => e
      UI.messagebox("Error writing to file: " + e.message)
    end
  end

end # Module
