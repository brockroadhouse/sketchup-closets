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
  @@cncParts = {}

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
    cncParts_json  = JSON.generate(@@cncParts)
    @settings_dialog.execute_script("updateData(#{options_json}, #{cncParts_json})")
  end

  def self.update_options_from_dialog(options)
    @@optsData.each do |key, data|
      data['value'] = options[key]['value'] if options.has_key?(key)
    end
    set_options(@@optsData)
  end

  ## Settings Functions ##
  def self.init
    to_load = {
      'settings.json' => @@opts,
      'parts.json' => @@cncParts
    }
    to_load.each do |file, optsVar| 
      defaultFile = File.join(__dir__, file)
      optionsFile = set_options_file(defaultFile, file)
      set_options_from_file(defaultFile, optionsFile, optsVar)
    end
  end

  def self.save_options(optionsFile)
    json_str = JSON.pretty_generate(@@optsData)
    File.open(optionsFile,"w") {|io| io.write(json_str) }
  end

  def self.set_options_file(defaultFile, file)
    # %APPDATA% #
    appdata = File::expand_path('../../..',Sketchup::find_support_file('Plugins'))

    # %APPDATA%/FVCC/Closets #
    dirpath = File::join(appdata,"FVCC")
    Dir::mkdir(dirpath) unless Dir::exist?(dirpath)

    plugpath = File::join(dirpath,"Closets")
    Dir::mkdir(plugpath) unless Dir::exist?(plugpath)

    optionsFile = File::join(plugpath,file)
    unless File::exist?(optionsFile)
      FileUtils.cp(defaultFile, optionsFile)
    end
    optionsFile
  end

  # Set values from default
  def self.set_options_from_file(defaultFile, optionsFile, optsVar)
    json_options = File.read(optionsFile)
    options = JSON.parse(json_options)

    def_json_options = File.read(defaultFile)
    def_options = JSON.parse(def_json_options)

    def_options.each do |key, option|
      options[key] = option unless options.key?(key)
    end
    set_options(options, optionsFile, optsVar)
  end

  def self.set_options(options, optionsFile, optsVar)
    @@optsData = options
    @@optsData.each do |key, option|
      case option['type']
      when "length"
        value = option['value'].to_l
      when "currency"
        value = option['value'].to_f
      when "percent"
        value = option['value'].to_f/100
      when "text"
        value = option['value']
      else
        value = option
      end
      optsVar[key] = value
    end
    save_options(optionsFile)

  end

  init

  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)
  end

end
