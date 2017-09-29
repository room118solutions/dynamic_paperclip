module DynamicPaperclip
  class HasAttachedFile < Paperclip::HasAttachedFile
    def register_new_attachment
      DynamicPaperclip::AttachmentRegistry.register(@klass, @name, @options)

      super
    end

    private

      # TODO: Are there any alternatives to literally copying this
      #       method from Paperclip::HasAttachedFile to get Ruby to find
      #       DynamicPaperclip::Attachment instead of Paperclip::Attachment?
      def define_instance_getter
        name = @name
        options = @options

        @klass.send :define_method, @name do |*args|
          ivar = "@attachment_#{name}"
          attachment = instance_variable_get(ivar)

          if attachment.nil?
            attachment = Attachment.new(name, self, options)
            instance_variable_set(ivar, attachment)
          end

          if args.length > 0
            attachment.to_s(args.first)
          else
            attachment
          end
        end
      end

      def add_active_record_callbacks
        name = @name
        @klass.send(:after_save) { send(name).send(:delete_dynamic_files) }
        super
      end
  end
end
