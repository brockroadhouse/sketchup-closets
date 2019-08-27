require 'json'
require 'fileutils'

module Closets

  ## Closet params
  attr_reader :thickness,
    :defaultW


  @@defaultW  = 25.inch
  @@move      = true
  @@hangDepth = 12.inch

  @@floorDepth = 14.75.inch
  @@floorHeight = 86.inch
  @@floorSpacing = 250.mm

  @@lhHeight  = 24.inch
  @@dhHeight  = 48.inch

  @@nameCount = 0

  ## Model variables ##
  @@currentEnt
  @@selection
  @currentGroup
  @@model

  ## Export params ##

  @@comps
  @@parts
  @@total = 0

  @optionsFile
  @defaultOptionsFile
  @@opts = {}
  @@optsData = {}

  ## Settings Dialog ##
  def self.create_settings_dialog
    htmlFile = File.join(__dir__, 'html', 'settings.html')

    options = {
      :dialog_title => "Settings",
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(520, 750)
    dialog.center
    dialog
  end

  def self.show_settings_dialog
    @settings_dialog ||= self.create_settings_dialog
    @settings_dialog.add_action_callback("ready") { |action_context|
      self.update_settings_dialog
      nil
    }
    @settings_dialog.add_action_callback("save") { |action_context, options|
      self.update_options_from_dialog(options)
      @settings_dialog.close
      nil
    }
    @settings_dialog.add_action_callback("cancel") { |action_context|
      @settings_dialog.close
      nil
    }
    @settings_dialog.visible? ? @settings_dialog.bring_to_front : @settings_dialog.show
  end

  def self.update_settings_dialog
    options_json  = JSON.generate(@@optsData)
    @settings_dialog.execute_script("updateData(#{options_json})")
  end

  def self.update_options_from_dialog(options)
    @@optsData.each do |key, data|
      data['value'] = options[key]['value'] if options.has_key?(key)
    end
    set_options(@@optsData)
  end

  ## Settings Functions ##
  def self.init
    @defaultOptionsFile = File.join(__dir__, 'settings.json')
    set_options_file
    set_options_from_file
  end

  def self.save_options
    json_str = JSON.pretty_generate(@@optsData)
    File.open(@optionsFile,"w") {|io| io.write(json_str) }
  end

  def self.set_options_file
    # %APPDATA% #
    appdata = File::expand_path('../../..',Sketchup::find_support_file('Plugins'))

    # %APPDATA%/FVCC/Closets #
    dirpath = File::join(appdata,"FVCC")
    Dir::mkdir(dirpath) unless Dir::exist?(dirpath)

    plugpath = File::join(dirpath,"Closets")
    Dir::mkdir(plugpath) unless Dir::exist?(plugpath)

    @optionsFile = File::join(plugpath,"settings.json")
    unless File::exist?(@optionsFile)
      FileUtils.cp(@defaultOptionsFile, @optionsFile)
    end
  end

  def self.set_options_from_file
    json_options = File.read(@optionsFile)
    options = JSON.parse(json_options)
    set_options(options)
  end

  def self.set_options(options)
    @@optsData = options
    @@optsData.each do |key, option|
      case option['type']
      when "length"
        value = option['value'].to_l
      when "currency"
        value = option['value'].to_f
      else
        value = option['value']
      end
      @@opts[key] = value
    end
    save_options
  end

  init

  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)
  end

end
