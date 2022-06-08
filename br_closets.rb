# frozen_string_literal: true

require "sketchup.rb"
require "extensions.rb"

module FVCC
  module Closets

    # Create the extension.
    loader = File.join(File.dirname(__FILE__), "br_closets", "main.rb")
    extension = SketchupExtension.new("Closets", loader)
    extension.description = "Closet Builder"
    extension.version     = "2.1.05"
    extension.creator     = "BROADHOUSE"
    extension.copyright   = "NONE"

    # Register the extension with so it show up in the Preference panel.
    Sketchup.register_extension(extension, true)
    init_settings

    # Reload extension by running this method from the Ruby Console:
    def self.reload
      pattern = File.join(__dir__, '*/*.rb')
      files = Dir.glob(pattern).each { |file|
        # Cannot use `Sketchup.load` because its an alias for `Sketchup.require`.
        load file
      }.size
      init_settings
      files
    end
  end
end
