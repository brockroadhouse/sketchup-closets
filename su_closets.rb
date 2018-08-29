# Copyright 2014 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that creates simple shape objects.  More info at
# https://github.com/SketchUp/shapes


require "sketchup.rb"
require "extensions.rb"

module FVCC
  module Closets

    # Create the extension.
    loader = File.join(File.dirname(__FILE__), "su_closets", "main.rb")
    extension = SketchupExtension.new("Menu Item", loader)
    extension.description = "Made menu item"
    extension.version     = "0.0.1"
    extension.creator     = "BROADHOUSE"
    extension.copyright   = "NONE"

    # Register the extension with so it show up in the Preference panel.
    Sketchup.register_extension(extension, true)

    # Reload extension by running this method from the Ruby Console:
    #   Example::HelloWorld.reload
    def self.reload
      # original_verbose = $VERBOSE
      # $VERBOSE = nil
      pattern = File.join(__dir__, '**/*.rb')
      Dir.glob(pattern).each { |file|
        # Cannot use `Sketchup.load` because its an alias for `Sketchup.require`.
        load file
      }.size
    #ensure
      #$VERBOSE = original_verbose
    end

  end # module Closets
end # module FVCC
