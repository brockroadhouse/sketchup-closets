# frozen_string_literal: true

require 'json'
require 'fileutils'

module FVCC::Closets

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
  @@dhHeight  = 1202.mm

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

  @@settingsFile = 'settings.json'
  @@partsFile = 'parts.json'
  
  @@settings = {
    @@settingsFile => @@opts,
    @@partsFile => @@cncParts
  }

  ## Parts Dialog ##
  def self.create_parts_dialog
    createDialog('parts.html', 'Parts List', [520, 750])
  end

  def self.show_parts_dialog
    @parts_dialog ||= self.create_parts_dialog
    @parts_dialog.add_action_callback("ready") { |action_context|
      self.update_parts_dialog
      nil
    }
    @parts_dialog.add_action_callback("save") { |action_context, options|
      @parts_dialog.close
      nil
    }
    @parts_dialog.add_action_callback("cancel") { |action_context|
      @parts_dialog.close
      nil
    }
    @parts_dialog.visible? ? @parts_dialog.bring_to_front : @parts_dialog.show
  end

  def self.update_parts_dialog
    parts  = JSON.generate(@@cncParts)
    @parts_dialog.execute_script("updateData(#{parts})")
  end

  ## Settings Dialog ##
  def self.create_settings_dialog
    createDialog('settings.html', 'Settings', [520, 750])
  end

  def self.show_settings_dialog
    @settings_dialog ||= self.create_settings_dialog
    @settings_dialog.add_action_callback("ready") { |action_context|
      self.update_settings_dialog
      nil
    }
    @settings_dialog.add_action_callback("save") { |action_context, options|
      self.update_options_from_dialog(options, @@settingsFile)
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
    options_json  = JSON.generate(@@optsData[@@settingsFile])
    @settings_dialog.execute_script("updateData(#{options_json})")
  end

  def self.update_options_from_dialog(options, file)
    @@optsData[file].each do |key, data|
      data['value'] = options[key]['value'] if options.has_key?(key)
    end
	optionsFile = File::join(getPluginPath(),file)
	optsVar = @@settings[file]
	set_options(options, optionsFile, optsVar, file)
    # save_options(, file)
  end

  ## Settings Functions ##
  def self.init_settings
    @@settings.each do |file, optsVar| 
      defaultFile = File.join(__dir__, file)
      optionsFile = set_options_file(defaultFile, file)
      set_options_from_file(defaultFile, optionsFile, optsVar, file)
    end
  end

  def self.save_options(optionsFile, file)
    json_str = JSON.pretty_generate(@@optsData[file])
    File.open(optionsFile,"w") {|io| io.write(json_str) }
  end

  def self.set_options_file(defaultFile, file)
    plugpath = getPluginPath()

    optionsFile = File::join(plugpath,file)
    unless File::exist?(optionsFile)
      FileUtils.cp(defaultFile, optionsFile)
    end
    optionsFile
  end
  
  def self.getPluginPath()
	# %APPDATA% #
    appdata = File::expand_path('../../..',Sketchup::find_support_file('Plugins'))

    # %APPDATA%/FVCC/Closets #
    dirpath = File::join(appdata,"FVCC")
    Dir::mkdir(dirpath) unless Dir::exist?(dirpath)

    plugpath = File::join(dirpath,"Closets")
    Dir::mkdir(plugpath) unless Dir::exist?(plugpath)
	
	plugpath
  end

  # Set values from default
  def self.set_options_from_file(defaultFile, optionsFile, optsVar, file)
    json_options = File.read(optionsFile)
    options = JSON.parse(json_options)

    def_json_options = File.read(defaultFile)
    def_options = JSON.parse(def_json_options)

    def_options.each do |key, option|
      options[key] = option unless options.key?(key)
    end
    set_options(options, optionsFile, optsVar, file)
  end

  def self.set_options(options, optionsFile, optsVar, file)
    @@optsData[file] = options
    options.each do |key, option|
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
    save_options(optionsFile, file)
  end

  def self.parts_reload
    src = File.join(__dir__, @@partsFile)
    dest = File::join(getPluginPath, @@partsFile)
    FileUtils.cp(src, dest)
  end

  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)
  end

end
