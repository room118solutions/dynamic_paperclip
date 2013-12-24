require 'rack/request'
require 'action_controller/metal/data_streaming'

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

          # The definition will be escaped twice in the URL, so we need to unescape it once.
          # We should always reference dynamic style names after escaping once - that's how they reside on the FS.
          style_name = StyleNaming.dynamic_style_name_from_definition(URI.unescape(match[:definition]), false)

          # Validate URL hash against requested style name
          raise Errors::InvalidHash unless DynamicPaperclip::UrlSecurity.valid_hash?(request.params['s'], style_name)

          # Only process style if it doesn't exist,
          # otherwise we may just be fielding a request for
          # an existing style (i.e. serve_static_assets is true)
          attachment.process_dynamic_style style_name unless attachment.exists?(style_name)

          return [
            200,
            {
              'Content-Type' => attachment.content_type,
              'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' => "inline; filename=#{File.basename(attachment.path(style_name))}"
            },
            ActionController::DataStreaming::FileBody.new(attachment.path(style_name))
          ]
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