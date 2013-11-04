module DynamicPaperclip
  class HasAttachedFile < Paperclip::HasAttachedFile
    def initialize(klass, name, options)
      super

      add_route!
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

      def add_route!
        url = (@options[:url] || Attachment.default_options[:url]).gsub(':id_partition', '*id_partition').gsub(':class', @klass.name.underscore.pluralize)
        action = "generate_#{@klass.name.underscore}"
        default_attachment = @name.to_s.downcase.pluralize

        Rails.application.routes do
          get url,
            :to => "DynamicPaperclip::AttachmentStyles##{action}",
            :defaults => { :attachment => default_attachment }
        end
      end
  end
end