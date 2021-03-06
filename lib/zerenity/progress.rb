require('zerenity/base')
module Zerenity
  # Displays a progress bar which can be updated via a processing
  # block which is passed a ProgressProxy object.
  #
  # ====Options
  # [:autoClose] The dialog will automatically close once the
  #              progressing block is complete.
  # [:cancellable] If set to true the Cancel button is enabled
  #                and the ProgressProxy#cancelled? will be set to true if it 
  #                is clicked. It is the responsibility of the processing block
  #                to monitor this attribute and perfom the necessary actions
  #                when it is ckicked.
  #
  # ====Example Usage
  #  Zerenity::Progress(:text=>"Processing...",:cancellable=>true,:title=>"Processing Files") do |progress|
  #    files.each_with_index do |file,index|
  #       progress.cancelled ? break : nil
  #       process_file(file)
  #       progress.update(index/files.size,"#{((index/files.size)*100).round}% Complete")
  #    end  
  #    if progress.cancelled?
  #      progress.text = "Cleaning up..."
  #      cleanup_files(files)
  #    end
  #  end
  def self.Progress(options={},&block)
    Progress.run(options,&block)
  end

  class Progress < Base # :nodoc:
    
    def self.check(options)
      super(options)
      options[:autoClose] ||= false
      options[:cancellable] ||= false
    end
    
    def self.build(dialog,options,progressProxy)
      super(dialog,options)
      label = Gtk::Label.new(options[:text])
      progressBar = Gtk::ProgressBar.new
      progressProxy.progressBar = progressBar
      progressBar.pulse_step = 0.02
      !options[:cancellable] ? options[:cancel_button].sensitive = false : nil
      options[:ok_button].sensitive = false
      dialog.vbox.add(label)
      dialog.vbox.add(progressBar)
    end

    def self.run(options={},&block)
      self.check(options)
      Gtk.init
      dialog = Gtk::Dialog.new(options[:title])
      result = nil
      progressProxy = Zerenity::ProgressProxy.new
      self.build(dialog,options,progressProxy)
      options[:cancel_button].signal_connect(CLICKED) do
        progressProxy.cancel!
      end
      options[:ok_button].signal_connect(CLICKED) do
        result = true
        dialog.destroy
        Gtk.main_quit
      end
      dialog.show_all
      gtkThread = Thread.new do 
        Gtk.main
      end
      block.call(progressProxy)
      if options[:autoClose]
        dialog.destroy
        Gtk.main_quit
        return true 
      end
      options[:ok_button].sensitive = true
      options[:cancel_button].sensitive = false 
      gtkThread.join
      return result
    end
  end

  # ProgressProxy allows you to update the progress of the 
  # Zerenity::Progress dialog. It also can alert the processing
  # block whether or not the Cancel button has been clicked.
  class ProgressProxy
    # An attribute indicating whether the Cancel button has been clicked.
    attr_reader :cancelled
    
    def initialize() # :nodoc:
      @progressBar = nil 
      @cancelled = false
    end
    
    def progressBar=(progressBar) # :nodoc:
      @progressBar = progressBar
    end
    
    # Updates the progress bar.
    #
    # ====Parameters
    # [percentage] The percentage completed. Values range from 0 to 1.
    # [text] Optional text that will be displayed in the progress area.
    def update(percentage,text=nil)
      @progressBar.text = text.to_s if text
      @progressBar.fraction = percentage.to_f
    end

    # When called will put the progress bar into 'pulse' mode. A 
    # small bar will move forwards and backwards across the progress
    # area. 
    def pulse(text=nil)
      @progressBar.text = text.to_s if text
      @progressBar.pulse
    end

    # Sets the text in the progress area.
    def text=(text)
      @progressBar.text = text.to_s
    end

    # Sets the percentage complete of the  progress bar. Must be in the range 0-1.
    def percentage=(percentage)
      @progressBar.fraction = percentage.to_f
    end

    # Alias for cancelled.
    def cancelled?
      @cancelled
    end

    def cancel! #:nodoc:
      @cancelled = true 
    end
  end
end
