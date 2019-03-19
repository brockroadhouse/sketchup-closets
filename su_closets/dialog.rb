require 'json'

module Closets

  def self.create_dialog
    htmlFile = File.join(__dir__, 'html', 'dialog.html')

    options = {
      :dialog_title => "Closet",
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(1000, 900)
    dialog.center
    dialog
  end

  def self.show_dialog
    @dialog ||= self.create_dialog
    @dialog.add_action_callback("ready") { |action_context|
      self.update_dialog
      nil
    }
    @dialog.add_action_callback("build") { |action_context, closet, left|
      self.build(closet, left)
      @dialog.close
      nil
    }
    @dialog.add_action_callback("cancel") { |action_context, value|
      @dialog.close
      nil
    }
    @dialog.visible? ? @dialog.bring_to_front : @dialog.show
  end

  def self.update_dialog
    closetHash = {
      :name => "Closet " + @@nameCount.to_s,
      :width => 114,
      :height => 84,
      :depthLeft => 24,
      :depthRight => 24,
      :wallHeight => 96,
      :floor => 0
    }
    types = [
      {:value => 'LH', :text => 'Long Hang'},
      {:value => 'DH', :text => 'Double Hang'},
      {:value => 'Shelves', :text => 'Shelves'},
      {:value => 'drawers', :text => 'Drawers'},
    ]
    sizes = [
      {:value => 'eq', :text => 'Equal'},
      {:value => 'set', :text => '24'},
    ]
    left = [
      {
        :type => '',
        :size => '',
      }
    ]


    closetJson  = JSON.pretty_generate(closetHash)
    typesJson   = JSON.pretty_generate(types)
    sizesJson   = JSON.pretty_generate(sizes)
    leftJson    = JSON.pretty_generate(left)
    @dialog.execute_script("updateCloset(#{closetJson}, #{typesJson}, #{sizesJson}, #{leftJson}, #{leftJson}, #{leftJson})")
  end

  def self.build(closet, left)
    puts closet
    puts left
    return
    startOperation('Build Walls', true, closet['name'])

    buildWalls(closet['name'], closet['width'], closet['depthLeft'], closet['depthRight'], 6, 6, closet['height'], closet['wallHeight'])

    endOperation
  end

end
