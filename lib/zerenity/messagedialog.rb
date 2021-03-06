require 'zerenity/base'

module Zerenity
  class MessageDialog < Base # :nodoc: 
    def self.build(dialog,options)
      options[:ok_button] = dialog.add_button(Gtk::Stock::OK,Gtk::Dialog::RESPONSE_OK)
      dialog.set_default_response(Gtk::Dialog::RESPONSE_OK)
    end
    
     def self.run(options={})
      self.check(options)
      dialog = Gtk::MessageDialog.new(nil,Gtk::Dialog::MODAL,options[:type],Gtk::MessageDialog::BUTTONS_NONE,options[:text])
      self.build(dialog,options)
      dialog.set_title(options[:title]) if options[:title]
      result = nil
      if options[:cancel_button]
        options[:cancel_button].signal_connect(CLICKED) do
          dialog.destroy
          Base.open_dialogs.delete(dialog)
          Gtk.main_quit unless Base.no_main_loop
        end
      end

      options[:ok_button].signal_connect(CLICKED) do
        result = true
        dialog.destroy
        Base.open_dialogs.delete(dialog)
        Gtk.main_quit unless Base.no_main_loop
      end
      dialog.show_all
      Base.open_dialogs << dialog
      Gtk.main unless Base.no_main_loop
      return result
    end
  end
end
