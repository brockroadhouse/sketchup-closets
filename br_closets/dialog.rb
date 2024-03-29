# frozen_string_literal: true

require 'json'

module FVCC::Closets

  def self.createDialog(file, title, size, options = {})
    htmlFile = File.join(__dir__, 'html', file)
    options = {
      :dialog_title => title,
      :preferences_key => "com.fvcc.closets",
      :style => UI::HtmlDialog::STYLE_DIALOG
    }

    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(size[0], size[1])
    dialog.center
    # dialog.set_on_closed { self.onClose }
    dialog

  end

  ## Room Dialog ##
  def self.createRoomDialog
    createDialog('room.html', "Create Walls", [520, 875])
  end

  def self.showRoomDialog
    @@nameCount += 1
    @room_dialog ||= self.createRoomDialog
    @room_dialog.add_action_callback("ready") { |action_context|
      self.updateRoomDialog
      nil
    }
    @room_dialog.add_action_callback("buildRoom") { |action_context, room, close|
      @room_dialog.close if self.buildRoom(room) && close
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
      :returnL => 6,
      :returnR => 6,
      :wallHeight => 96,
    }

    closetJson  = JSON.pretty_generate(closetHash)
    @room_dialog.execute_script("updateCloset(#{closetJson})")
  end

  def self.buildRoom(closet)
    startOperation('Build Walls', true, closet['name'])
    begin
      buildWalls(
        closet['name'],
        closet['width'].to_l,
        closet['depthLeft'].to_l,
        closet['depthRight'].to_l,
        closet['returnL'].to_l,
        closet['returnR'].to_l,
        closet['height'].to_l,
        closet['wallHeight'].to_l
      )
    rescue => e
      puts "error: " + e.message
      abort
      return false
    end
    endOperation
  end

  ## Build Dialog ##
  def self.create_dialog
    createDialog('dialog.html', "Build Closet", [800, 800])
  end

  def self.show_dialog
    @dialog ||= self.create_dialog
    unless(@dialog.visible?)
      @dialog.add_action_callback("build") { |action_context, closet, params|
        errors = self.verifyParams(closet, params)
        if (errors.empty?)
          begin
            success = self.build(closet, params)
          rescue => e
            message = displayError(e)
            self.dialogError([e])
            success = false
          end
        else
          self.dialogError(errors)
          success = false
        end
        @dialog.execute_script("success(#{success})")
        nil
      }
      @dialog.add_action_callback("unbuild") { |action_context, closet, params|
        Sketchup.undo
        nil
      }
      @dialog.add_action_callback("cancel") { |action_context, value|
        @dialog.close
      }
    end
    @dialog.add_action_callback("ready") { |action_context|
      self.update_dialog
      nil
    }
    @dialog.visible? ? @dialog.bring_to_front : @dialog.show
  end

  def self.update_dialog
    self.setSelection

    closets = [
      {
        :type => '',
        :width => '',
        :depth => '',
        :drawers => '',
        :shelves => '',
        :height => '',
        :reverse => false,
        :doors => false,
        :drawerHeight => [10],
        :floor => false,
        :finished => false,
      }
    ]
    closetParams = {
      width: defaultWidth.to_l,
      gapLeft: 0.25.inch,
      gapRight: 0.25.inch,
      height: selectionHeight == 0 ? 84.inch : selectionHeight.to_l,
      bbHeight: 5.5.inch,
      bbDepth: 0.625.inch,
      placement: 'Center'
    }
    types = {
      'LH' => {:sections => 'six', :floorSections => 'six', :depth => 12, :height => 24, :shelves => 3},
      'DH' => {:sections => 'four', :floorSections => 'four', :depth => 12, :height => 48, :shelves => 0},
      'Shelves' => {:sections => 'eight', :floorSections => 'seven', :depth => '14 3/4', :height => 76, :shelves => 5},
      'Corner' => {:sections => 'four', :floorSections => 'four', :depth => 12},
    }
    placements = [
      {:value => 'Left', :text => 'L'},
      {:value => 'Center', :text => 'C'},
      {:value => 'Right', :text => 'R'},
    ]


    closetsJson       = JSON.generate(closets)
    closetParamsJson  = JSON.generate(closetParams)
    typesJson         = JSON.generate(types)
    placementsJson    = JSON.generate(placements)
    @dialog.execute_script("updateCloset(#{closetsJson}, #{closetParamsJson}, #{typesJson}, #{placementsJson})")
  end

  def self.update_width(selection)
    return unless selectionIsEdge && @dialog
    updateHash = {
      :width => defaultWidth.to_l,
      :height => selectionHeight
    }

    updateJson    = JSON.generate(updateHash)
    @dialog.execute_script("updateParams(#{updateJson})")
  end

  def self.dialogError(message)
    return if message.empty?
    jsonError = JSON.generate(message)
    @dialog.execute_script("updateError(#{jsonError})")
  end

  def self.on_selection_change(selection)
    self.update_width(selection)
  end

  ## Selection Observers ##
  PLUGIN ||= self
  class SelectionChangeObserver < Sketchup::SelectionObserver
    def onSelectionBulkChange(selection)
      PLUGIN.on_selection_change(selection)
    end
  end

  class AppObserver < Sketchup::AppObserver
    def onNewModel(model)
      observe_model(model)
    end
    def onOpenModel(model)
      observe_model(model)
    end
    def expectsStartupModelNotifications
      return true
    end
    private
    def observe_model(model)
      model.selection.add_observer(SelectionChangeObserver.new)
    end
  end

  unless file_loaded?(__FILE__)
    Sketchup.add_observer(AppObserver.new)
  end

end
