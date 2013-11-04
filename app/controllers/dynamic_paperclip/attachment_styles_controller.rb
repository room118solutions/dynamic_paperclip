module DynamicPaperclip
  class AttachmentStylesController < ApplicationController
    def action_missing(name, *args, &block)
      if name =~ /^generate_(.+)$/
        send :generate, $1
      end
    end

    private

      def generate(class_name)
        klass = class_name.camelize.constantize
        attachment_name = params[:attachment].singularize.to_sym

        # Ensure that we have a valid attachment name and an ID
        raise Errors::UndefinedAttachment unless klass.attachment_definitions[attachment_name]
        raise Errors::MissingID unless params[:id] || params[:id_partition]

        id = params[:id] || id_from_partition(params[:id_partition])

        attachment = klass.find(id).send(attachment_name)

        # The definition will be escaped twice in the URL, Rails will unescape it once for us,
        # so it will already be escaped once, so we don't need to escape it again. We should always
        # reference dynamic style names after escaping once - that's how they reside on the FS.
        style_name = StyleNaming.dynamic_style_name_from_definition(params[:definition], false)

        # Validate URL hash against requested style name
        raise Errors::InvalidHash unless DynamicPaperclip::UrlSecurity.valid_hash?(params[:s], style_name)

        # Only process style if it doesn't exist,
        # otherwise we may just be fielding a request for
        # an existing style (i.e. serve_static_assets is true)
        attachment.process_dynamic_style style_name unless attachment.exists?(style_name)

        send_file attachment.path(style_name), :disposition => 'inline', :type => attachment.content_type
      end

      def id_from_partition(partition)
        partition.gsub('/', '').to_i
      end
  end
end