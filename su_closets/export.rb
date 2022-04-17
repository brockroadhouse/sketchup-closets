require "csv"
require "su_closets/svg.rb"

module Closets

  def self.viewQuoteList
    startOperation("View Quote", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
    setPartsList
    showQuoteDialog

    endOperation
  end # export

  def self.exportCutList
    startOperation("Export Cut List", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
    setCutListParts
    showCutlistDialog
    # exportCutListCsv

    endOperation
  end # export

  def self.exportSvg
    startOperation("Export SVG", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
    setPartsList
    renderSvg

    endOperation
  end

  def self.setParts
    @@total     = 0
    @@subTotal  = 0
    @@comps     = Hash.new
    @@selection.each do |s|
      getSelectionComps(s)
    end
  end

  def self.setPartsList
    @@parts = Hash.new
    @@closetTotals = Hash.new
    @@edgetape = 0
    @@comps.each do |group, components|
      closetTotal = 0
      @@parts[group] = Array.new
      components.each do |guid, comp|
        name = comp[:instance].name
        inst = comp[:instance].bounds
        c = comp[:count]
        w = inst.width
        h = inst.height
        d = inst.depth
        cost = 0


        # file << ["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"]
        if (name.include? "Gable")
          cost = c*h.to_f*d.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Gable", c, h, d, w, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
          @@edgetape +=  c*(d.to_f + h.to_f)
        elsif (name.include? "Shelf")
          cost = c*w.to_f*h.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Shelf", c, w.to_l, h.to_l, d, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
          @@edgetape +=  c*w.to_f
        elsif (name.include? "Cleat")
          cost = c*w.to_f*d.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Cleat", c, w, d, h, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
          @@edgetape +=  c*w.to_f
        elsif (name.include? "Door")
          rate = w.to_f*d.to_f*@@opts['cost'].to_f + hingeCost(d)
          cost = c*rate
          @@parts[group] << ["Door", c, w, d, h, sprintf("$%2.2f",rate), sprintf("$%2.2f", cost)]
          @@edgetape +=  c*(w.to_f + d.to_f)*2
        elsif (name.include? "Drawer")
          rate = (w.to_f*d.to_f*@@opts['cost'].to_f+@@opts['drawerCost'].to_f)
          cost = c*rate
          @@parts[group] << ["Drawer", c, w, d, h,sprintf("$%2.2f",rate), sprintf("$%2.2f", cost)]
          @@edgetape +=  c*(w.to_f + d.to_f)*2
        elsif (name.include? "Rod")
          cost = c*w.to_f*@@opts['rodCost'].to_f
          @@parts[group] << ["Rod", c, w, '1"', '1.5"', sprintf("$%2.2f", @@opts['rodCost']), sprintf("$%2.2f", cost)]
        elsif (name.include? "Rail")
          cost = c*w.to_f*@@opts['railCost'].to_f
          @@parts[group] << ["Wall Rail", c, w, '1"', '1"', sprintf("$%2.2f", @@opts['railCost']), sprintf("$%2.2f", cost)]
        end
        closetTotal += cost
      end
      @@edgetape = @@edgetape.to_feet.round
      @@parts[group].sort! {|a,b| a[0] <=> b[0] }
      @@parts[group] << ["", "", "", "", "", "Closet Total", sprintf("$%2.2f", closetTotal)]
      @@closetTotals[group] = closetTotal.round(2)
      @@subTotal += closetTotal
    end
    @@subTotal = @@subTotal.round(2)
    @@total = (@@subTotal * (1+@@opts['tax'])).round(2)

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

  def self.hingeCost(height)
    if (height <= 36.inch)
      hinges = 2
    elsif (height > 60.inch)
      hinges = 4
    else
      hinges = 3
    end
    return hinges*@@opts['hingeCost'].to_f
  end

  def self.exportCsv(discount = 0)
    title = @@model.title.length > 0 ? @@model.title : "Quote"
    filename = UI.savepanel("Save Quote", Dir::pwd, 'CSV file|*.csv||')
    return unless filename
    filename << ".csv" unless filename[-4..-1] == ".csv"

    begin
      CSV.open(filename, "wb") do |file|
        file << ["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"]
        @@parts.each do |group, items|
          file << [group]
          items.each do |line|
            file << line
          end
        end
        file << [""]
        @@closetTotals.each do |name, closetTotal|
          file << ["", "", "", "", "", name, sprintf("$%2.2f", closetTotal)]
        end
        unless (discount == 0)
          file << ["", "", "", "", "", "Discount (%):", sprintf("%2.2f", discount)]
          file << ["", "", "", "", "", "Discount:", sprintf("$%2.2f", @@subTotal*(-discount/100))]
        end
        subtotal = (@@subTotal*(1-discount/100)).round(2)
        tax      = (@@opts['tax'] * subtotal).round(2)
        total    = subtotal + tax

        file << ["", "", "", "", "", "Sub-Total:", sprintf("$%2.2f", subtotal)]
        file << ["", "", "", "", "", "Tax:", sprintf("$%2.2f", tax)]
        file << ["", "", "", "", "", "Total:", sprintf("$%2.2f", total)]

      end
    rescue => e
      UI.messagebox("Error writing to file: " + e.message)
    end
  end

  def self.postProcessGable(height, depth, thickness)

    height = (( (height-18) / 32 ).to_i) * 32 + 18
    depth  = 376 if depth == 375

    return [height, depth, thickness]
  end

  def self.postProcessShelf(width, depth, thickness)

    if depth == 375
      depth  = 376 
    elsif depth == 305
      depth = 300
    end

    return [width, depth, thickness]
  end

  def self.setCutListParts
    @@cutList = Array.new
    @@comps.each do |group, components|
      components.each do |guid, comp|
        instance = comp[:instance]
        instname = instance.name
        name = instance.get_attribute("cnc_params", "partName", instname)
        inst = instance.bounds
        c = comp[:count]
        w = inst.width.to_mm.round
        h = inst.height.to_mm.round
        d = inst.depth.to_mm.round

        # CNC Options
        partName = instance.get_attribute("cutlist", "partName", name)
        part = @@opts["programLocation"] + partName + "." + @@opts["programType"]
        material = @@opts["woodType"]
        params = instance.get_attribute("cnc_params", "params")

        # Only add parts to cut
        if (["Rail", "Rod"].any?{|piece| name.include? piece})
          next
        elsif (name.include? "Gable")
          dimension = postProcessGable(d, h, w)
        elsif (name.include? "Shelf")
          dimension = postProcessShelf(w, h, d)
        elsif (name.include? "Drawer")
          width      = instance.get_attribute("cnc_params", "width")
          dimension = [width, d, h]
        elsif (["Cleat", "Door"].any?{|piece| name.include? piece})
          dimension = [w, d, h]
        else
          dimension = [d, h, w]
        end

        # Headers for import:
        # ["Qty", "material", "partname", "width", "height", "thickness", "margin", "grainDirection", "name", "params"]

        @@cutList << [c, material, part, 0, 0, partName, params].insert(3, *dimension)
      end
    end

  end # setCutListParts

  def self.exportCutListCsv()
    title = @@model.title.length > 0 ? @@model.title : "Cut List"
    filename = UI.savepanel("Save Cut List", Dir::pwd, 'CSV file|*.csv||')
    return unless filename
    filename << ".csv" unless filename[-4..-1] == ".csv"

    begin
      CSV.open(filename, "wb") do |file|

        file << ["Qty", "material", "partname", "width", "height", "thickness", "margin", "grainDirection", "name", "params"]
        @@cutList.each do |line|
          file << line
        end

      end
    rescue => e
      UI.messagebox("Error writing to file: " + e.message)
    end
  end

  def self.viewQuote
    title = @@model.title.length > 0 ? @@model.title + " Quote" : "Quote"
    createDialog('quote.html', title, [800, 800])
  end

  def self.showQuoteDialog

    @quote_dialog ||= self.viewQuote
    @quote_dialog.add_action_callback("ready") { |action_context|
      partsJson   = JSON.generate(@@parts)
      headersJson = JSON.generate(["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"])
      closetsJson   = @@closetTotals.to_json
      taxJson   = @@opts['tax'].round(2).to_json
      subTotalJson   = @@subTotal.to_json
      totalJson   = @@total.to_json
      edgetapeJson   = @@edgetape.to_json
      @quote_dialog.execute_script("updateData(
        #{partsJson},
        #{headersJson},
        #{closetsJson},
        #{subTotalJson},
        #{taxJson},
        #{totalJson},
        #{edgetapeJson})")
      nil
    }
    @quote_dialog.add_action_callback("exportCsv") { |action_context, discount|
      exportCsv(discount.to_f)
      nil
    }
    @quote_dialog.add_action_callback("cancel") { |action_context, value|
      @quote_dialog.close
      nil
    }
    @quote_dialog.visible? ? @quote_dialog.bring_to_front : @quote_dialog.show
  end

  def self.viewCutlist
    title = @@model.title.length > 0 ? @@model.title + " Cutlist" : "Cutlist"

    createDialog('cutlist.html', title, [800, 800])
  end

  def self.showCutlistDialog

    @cutlist_dialog ||= self.viewCutlist
    @cutlist_dialog.add_action_callback("ready") { |action_context|
      cutlist   = JSON.generate(@@cutList)
      headers   = JSON.generate(["Qty", "material", "partname", "width", "height", "thickness", "margin", "grainDirection", "name", "params"])
      @cutlist_dialog.execute_script("updateData(#{cutlist}, #{headers})")
      nil
    }
    @cutlist_dialog.add_action_callback("exportCsv") { |action_context|
      exportCutListCsv
      nil
    }
    @cutlist_dialog.add_action_callback("cancel") { |action_context|
      @cutlist_dialog.close
      nil
    }
    @cutlist_dialog.visible? ? @cutlist_dialog.bring_to_front : @cutlist_dialog.show
  end

end # Module
