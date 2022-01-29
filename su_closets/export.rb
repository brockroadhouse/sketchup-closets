require "csv"
require "su_closets/svg.rb"

module Closets

  def self.exportQuote
    startOperation("Export Quote", false)
    if (@@selection.length < 1)
      UI.messagebox("Nothing selected.")
      return
    end

    setParts
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
    exportCutListCsv

    endOperation
  end # export cut list

  def self.setParts
    @@total     = 0
    @@subTotal  = 0
    @@comps     = Hash.new
    @cncParts  = Hash.new
    @@selection.each do |s|
      getSelectionComps(s)
    end
    setPartsList
  end

  def self.setPartsList
    @@parts = Hash.new
    @@closetTotals = Hash.new
    @@comps.each do |group, components|
      closetTotal = 0
      @@parts[group] = Array.new unless @@parts.has_key?(group)
      components.each do |guid, comp|
        name = comp[:instance].name
        inst = comp[:instance].bounds
        c = comp[:count]
        w = inst.width
        h = inst.height
        d = inst.depth
        cost = 0

        if (name.include? "Gable")
          cost = c*h.to_f*d.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Gable", c, h, d, w, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
        elsif (name.include? "Shelf")
          cost = c*w.to_f*h.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Shelf", c, w.to_l, h.to_l, d, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
        elsif (name.include? "Cleat")
          cost = c*w.to_f*d.to_f*@@opts['cost'].to_f
          @@parts[group] << ["Cleat", c, w, d, h, sprintf("$%2.2f", @@opts['cost']), sprintf("$%2.2f", cost)]
        elsif (name.include? "Door")
          rate = w.to_f*d.to_f*@@opts['cost'].to_f + hingeCost(d)
          cost = c*rate
          @@parts[group] << ["Door", c, w, d, h, sprintf("$%2.2f",rate), sprintf("$%2.2f", cost)]
        elsif (name.include? "Drawer")
          rate = (w.to_f*d.to_f*@@opts['cost'].to_f+@@opts['drawerCost'].to_f)
          cost = c*rate
          @@parts[group] << ["Drawer", c, w, d, h,sprintf("$%2.2f",rate), sprintf("$%2.2f", cost)]
        elsif (name.include? "Rod")
          cost = c*w.to_f*@@opts['rodCost'].to_f
          @@parts[group] << ["Rod", c, w, '1"', '1.5"', sprintf("$%2.2f", @@opts['rodCost']), sprintf("$%2.2f", cost)]
        elsif (name.include? "Rail")
          cost = c*w.to_f*@@opts['railCost'].to_f
          @@parts[group] << ["Wall Rail", c, w, '1"', '1"', sprintf("$%2.2f", @@opts['railCost']), sprintf("$%2.2f", cost)]
        end
        closetTotal += cost
      end
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
      addToCutList(s)
      guid = s.definition.guid
      name = 'Ungrouped' if (name.to_s.strip.empty?)
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

  def self.addToCutList(instance)
    dict = instance.attribute_dictionary("cnc")
    return if dict.nil? || !@@cncData.key?(dict['name']) 
    key = dict.values.join("-")
    
    @cncParts[key] = {:count => 1, :attributes => dict} unless (@cncParts.has_key? key)
    @cncParts[key][:count] = @cncParts[key][:count]+1
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

  def self.exportCutListCsv()
    title = @@model.title.length > 0 ? @@model.title : "Cut List"
    filename = UI.savepanel("Save Cut List", Dir::pwd, 'CSV file|*.csv||')
    return unless filename
    filename << ".csv" unless filename[-4..-1] == ".csv"

    begin
     CSV.open(filename, "wb") do |file|
        file << [
          "qty", 
          "material", 
          "program", 
          "width", 
          "height", 
          "depth", 
          "grain", 
          "margin"
        ]
        p @@cncData

        @cncParts.each do |key, part|
          attributes = part[:attributes]
          
          file << [
            part[:count], 
            "white", 
            @@cncData[attributes['name']]['programName'],
            attributes['width'].to_mm.round, 
            attributes['depth'].to_mm.round, 
            @@opts['thickness'].to_mm.round,
            1, 
            0
          ]
        end
      end
    rescue => e
      p e
      UI.messagebox("Error writing to file: " + e.message)
      pp e
    end
  end

  def self.viewQuote
    title = @@model.title.length > 0 ? @@model.title + " Quote" : "Quote"
    htmlFile = File.join(__dir__, 'html', 'quote.html')

    options = {
      :dialog_title => title,
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(800, 800)
    dialog.set_on_closed { self.onClose }
    dialog.center
    dialog
  end

  def self.onClose
    @quote_dialog = nil
  end

  def self.showQuoteDialog

    @quote_dialog ||= self.viewQuote
    @quote_dialog.add_action_callback("ready") { |action_context|
      partsJson   = JSON.generate(@@parts)
      headersJson = JSON.generate(["Name", "Qty", "Width", "Height", "Depth", "Unit Price", "Price"])
      closetsJson   = @@closetTotals.to_json
      taxJson   = @@opts['tax'].to_json
      subTotalJson   = @@subTotal.to_json
      totalJson   = @@total.to_json
      @quote_dialog.execute_script("updateData(
        #{partsJson},
        #{headersJson},
        #{closetsJson},
        #{subTotalJson},
        #{taxJson},
        #{totalJson})")
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

end # Module
