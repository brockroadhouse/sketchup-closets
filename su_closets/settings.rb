require 'json'

module Closets

  ## Closet params
  attr_reader :thickness,
    :defaultW


  @@defaultW  = 25.inch
  @@cleat     = 5.inch
  @@move      = true
  @@drawer    = 10.inch
  @@hangDepth = 12.inch

  @@floorDepth = 14.75.inch
  @@floorHeight = 86.inch
  @@floorSpacing = 250.mm

  @@lhHeight  = 24.inch
  @@dhHeight  = 48.inch

  @@nameCount = 1

  ## Model variables ##
  @@currentEnt
  @@selection
  @currentGroup
  @@model

  ## Export params ##
  @@comps
  @@parts
  @@cost = 0.09
  @@rodCost = 0.5
  @@railCost = 0.4
  @@drawerCost = 77.5
  @@hingeCost = 10
  @@total = 0

  @optionsFile
  @options

  def self.set_defaults
    @thickness = 0.75.inch
    @defaultW = 25.inch
    #save_options
  end

  def self.save_options
    json_str = JSON.generate(@options)
    File.open(@optionsFile,"w:UTF-8:#{__ENCODING__}") {|io| io.write(json_str) }
  end

  def self.retrieve_options
    if false && File::exist?(@optionsFile)
      json_str = File.read(@optionsFile,"r:UTF-8:#{__ENCODING__}")
      @options = JSON.parse(json_str)
    else
      set_defaults
    end
  end

  def self.set_options
    # %APPDATA% #
    appdata = File::expand_path('../../..',Sketchup::find_support_file('Plugins'))

    # %APPDATA%/FVCC/Closets #
    dirpath = File::join(appdata,"FVCC")
    Dir::mkdir(dirpath) unless Dir::exist?(dirpath)
    plugpath = File::join(dirpath,"Closets")
    Dir::mkdir(plugpath) unless Dir::exist?(plugpath)
    @optionsFile = File::join(plugpath,"settings.json")

    retrieve_options
  end

  unless file_loaded?(__FILE__)
    set_options
    file_loaded(__FILE__)
  end

end
