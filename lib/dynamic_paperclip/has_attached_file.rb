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
        url = (@options[:url] || Attachment.default_options[:url]).
              gsub(':id_partition', '*id_partition').
              gsub(':class'       , @klass.name.underscore.pluralize).
              gsub(':style'       , "dynamic_:definition")

        action = "generate_#{@klass.name.underscore}"
        default_attachment = @name.to_s.downcase.pluralize

        route_options = {
          :to => "DynamicPaperclip::AttachmentStyles##{action}",
          :defaults => { :attachment => default_attachment }
        }

        # If the routes have not been finalized yet, we can just add them as we normally would.
        # This should always be the case whenever class caching is enabled (i.e. production)
        # If they have been finalized, we need to hack around a bit to get this added at runtime (primarily for development)
        if Rails.application.routes.disable_clear_and_finalize
          Rails.application.routes do
            get url, route_options
          end
        else
          add_runtime_route! url, route_options
        end
      end

      def add_runtime_route!(url, options)
        begin
          _routes = Rails.application.routes
          _routes.disable_clear_and_finalize = true
          _routes.clear!

          Rails.application.routes_reloader.paths.each{ |path| load(path) }

          _routes.draw do
            get url, options
          end

          ActiveSupport.on_load(:action_controller) { _routes.finalize! }
        ensure
          _routes.disable_clear_and_finalize = false
        end
      end
  end
end