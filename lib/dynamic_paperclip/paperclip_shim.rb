module Paperclip
  module ClassMethods
    def has_dynamic_attached_file(name, options = {})
      DynamicPaperclip::HasAttachedFile.define_on(self, name, options)
    end
  end
end