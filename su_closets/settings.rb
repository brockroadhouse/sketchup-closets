# frozen_string_literal: true

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

    @@optionsFile = 'settings.json'
    @@cncFile = 'cnc.json'
    @defaultOptionsFile
    @@opts = {}
    @@optsData = {}
    @@cncData = {}

    ## Settings Dialog ##
    def self.create_settings_dialog
        htmlFile = File.join(__dir__, 'html', 'settings.html')

        options = {
            dialog_title: 'Settings',
            preferences_key: 'com.fvcc.closets',
            style: UI::HtmlDialog::STYLE_DIALOG
        }
        dialog = UI::HtmlDialog.new(options)
        dialog.set_file(htmlFile)
        dialog.set_size(600, 750)
        dialog.center
        dialog
    end

    def self.show_settings_dialog
        @settings_dialog ||= create_settings_dialog
        @settings_dialog.add_action_callback('ready') do |_action_context|
            update_settings_dialog
            nil
        end
        @settings_dialog.add_action_callback('save') do |_action_context, options, cncOptions|
            update_options_from_dialog(options, cncOptions)
            @settings_dialog.close
            nil
        end
        @settings_dialog.add_action_callback('cancel') do |_action_context|
            @settings_dialog.close
            nil
        end
        @settings_dialog.visible? ? @settings_dialog.bring_to_front : @settings_dialog.show
    end

    def self.update_settings_dialog
        options_json = JSON.generate(@@optsData)
        cnc_json = JSON.generate(@@cncData)
        @settings_dialog.execute_script("updateData(#{options_json}, #{cnc_json})")
    end

    def self.update_options_from_dialog(options, cncOptions)
        @@optsData.each do |key, data|
            data['value'] = options[key]['value'] if options.key?(key)
        end
        set_options(@@optsData)

        @@cncData.each do |key, cnc|
            @@cncData[key] = cncOptions[key] if cncOptions.key?(key)
        end
        save_options(@@cncData, @@cncFile)
    end

    ## Settings Functions ##
    def self.init
        [@@optionsFile, @@cncFile].each do |filename|
            set_options_file(filename)
        end
        # Set & save options
        set_options(get_options_from_file(@@optionsFile))

        # Save CNC options
        @@cncData = get_options_from_file(@@cncFile)
        save_options(@@cncData, @@cncFile)
    end

    def self.set_options_file(name)
        optionsFile = plugin_filepath(name)
        unless File.exist?(optionsFile)
            FileUtils.cp(default_file(name), optionsFile)
        end
    end

    def self.get_options_from_file(name)
        options = JSON.parse(File.read(plugin_filepath(name)))
        def_options = JSON.parse(File.read(default_file(name)))

        def_options.each do |key, def_option|
            options[key] = def_option unless options.key?(key)
        end
        options
    end

    def self.set_options(options)
        @@optsData = options
        @@optsData.each do |key, option|
            value = case option['type']
                    when 'length'
                        option['value'].to_l
                    when 'currency'
                        option['value'].to_f
                    when 'percent'
                        option['value'].to_f / 100
                    else
                        option['value']
                    end
            @@opts[key] = value
        end
        save_options(@@optsData, @@optionsFile)
    end

    def self.save_options(options, file)
        json_str = JSON.pretty_generate(options)
        File.open(plugin_filepath(file), 'w') { |io| io.write(json_str) }
    end

    def self.default_file(name)
        File.join(__dir__, name)
    end

    def self.plugin_filepath(name)
        # %APPDATA% #
        appdata = File.expand_path('../../..', Sketchup.find_support_file('Plugins'))

        # %APPDATA%/FVCC/Closets #
        dirpath = File.join(appdata, 'FVCC')
        Dir.mkdir(dirpath) unless Dir.exist?(dirpath)

        plugpath = File.join(dirpath, 'Closets')
        Dir.mkdir(plugpath) unless Dir.exist?(plugpath)

        File.join(plugpath, name)
    end

    init

    file_loaded(__FILE__) unless file_loaded?(__FILE__)
end
