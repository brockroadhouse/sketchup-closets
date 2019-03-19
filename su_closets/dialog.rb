require 'json'

module Closets

  def self.create_dialog
    htmlFile = File.join(__dir__, 'html', 'dialog.html')

    options = {
      :dialog_title => "",
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(600, 400)
    dialog.center
    dialog
  end

  def self.createRoomDialog
    htmlFile = File.join(__dir__, 'html', 'room.html')

    options = {
      :dialog_title => "Create Walls",
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(500, 400)
    dialog.center
    dialog
  end

  def self.show_dialog
    @dialog ||= self.create_dialog
    @dialog.add_action_callback("ready") { |action_context|
      self.update_dialog
      nil
    }
    @dialog.add_action_callback("build") { |action_context, closet|
      self.build(closet)
      @dialog.close
      nil
    }
    @dialog.add_action_callback("cancel") { |action_context, value|
      @dialog.close
      nil
    }
    @dialog.visible? ? @dialog.bring_to_front : @dialog.show
  end

  def self.showRoomDialog
    @room_dialog ||= self.createRoomDialog
    @room_dialog.add_action_callback("ready") { |action_context|
      self.updateRoomDialog
      nil
    }
    @room_dialog.add_action_callback("buildRoom") { |action_context, room|
      self.buildRoom(room)
      @room_dialog.close
      nil
    }
    @room_dialog.add_action_callback("cancel") { |action_context, value|
      @room_dialog.close
      nil
    }
    @room_dialog.visible? ? @room_dialog.bring_to_front : @room_dialog.show
  end

  def self.updateRoomDialog
    closetHash = {
      :name => "Closet " + @@nameCount.to_s,
      :width => 50,
      :height => 84,
      :depthLeft => 24,
      :depthRight => 24,
      :wallHeight => 96,
    }


    closetJson  = JSON.pretty_generate(closetHash)
    @room_dialog.execute_script("updateCloset(#{closetJson})")
  end

  def self.update_dialog
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
    closets = [
      {
        :type => '-',
        :size => '-',
      }
    ]


    closetsJson  = JSON.pretty_generate(closets)
    typesJson   = JSON.pretty_generate(types)
    sizesJson   = JSON.pretty_generate(sizes)
    @dialog.execute_script("updateCloset(#{closetsJson}, #{typesJson}, #{sizesJson})")
  end

  def self.buildRoom(closet)
    startOperation('Build Walls', true, closet['name'])

    buildWalls(
      closet['name'],
      closet['width'].to_l,
      closet['depthLeft'].to_l,
      closet['depthRight'].to_l,
      closet['height'].to_l,
      closet['wallHeight'].to_l
    )

    endOperation
  end

  def self.build(closet)
    puts closet
    return
    startOperation('Build Closet')

    endOperation
  end

end
