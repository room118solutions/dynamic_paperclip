require 'rack/request'

require 'action_controller/metal/data_streaming' # For Rails 4
require 'action_dispatch/http/response.rb' # For Rails 5

module DynamicPaperclip
  class AttachmentStyleGenerator
    # Rack middleware that catches requests for dynamic attachment styles
    # that have not yet been generated and generates them.

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      DynamicPaperclip::AttachmentRegistry.each_definition do |klass, name, options|
        if match = regexp_for_attachment_url(klass, (options[:url] || Attachment.default_options[:url])).match(request.path)
          id = id_from_partition(match[:id])
          attachment = klass.find(id).send(name)

          # When the filename is wrong, return a 404
          if !attachment.exists? || attachment.original_filename != URI.unescape(match[:filename])
            return [404, {}, []]
          end

          # The definition will be escaped twice in the URL, so we need to unescape it once.
          # We should always reference dynamic style names after escaping once - that's how they reside on the FS.
          style_name = StyleNaming.dynamic_style_name_from_definition(CGI.unescape(match[:definition]), false)

          # Validate URL hash against requested style name
          if DynamicPaperclip::UrlSecurity.valid_hash?(request.params['s'], style_name)

            # Only process style if it doesn't exist,
            # otherwise we may just be fielding a request for
            # an existing style
            attachment.process_dynamic_style style_name unless attachment.exists?(style_name)

            # The FileBody class has been moved to another module in Rails 5
            file_body = defined?(ActionController::DataStreaming::FileBody) ? ActionController::DataStreaming::FileBody : ActionDispatch::Response::FileBody

            return [
              200,
              {
                'Content-Type' => attachment.content_type,
                'Content-Transfer-Encoding' => 'binary',
                'Content-Disposition' => "inline; filename=#{File.basename(attachment.path(style_name))}"
              },
              file_body.new(attachment.path(style_name))
            ]
          else
            # Invalid hash, just 403

            return [403, {}, []]
          end
        end
      end

      @app.call env
    end

    private

      def regexp_for_attachment_url(klass, url)
        Regexp.new '^' + url.
          gsub('.'            , '\.').
          gsub(':id_partition', '(?<id>.*)').
          gsub(':class'       , klass.name.underscore.pluralize).
          gsub(':style'       , "dynamic_#{url_named_capture_group('definition')}").
          gsub(/\:(\w+)/      , url_named_capture_group('\1')) + '$'
      end

      def url_named_capture_group(name)
        "(?<#{name}>[^\/]*)"
      end

      def id_from_partition(partition)
        partition.gsub('/', '').to_i
      end

  end
end
