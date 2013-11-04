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

        # Only validate style name if it's dynamic,
        # and only process style if it's dynamic and doesn't exist,
        # otherwise we may just be fielding a request for
        # an existing style (i.e. serve_static_assets is true)
        if params[:style] =~ /^dynamic_/
          raise Errors::InvalidHash unless DynamicPaperclip::UrlSecurity.valid_hash?(params[:s], params[:style])

          attachment.process_dynamic_style params[:style] unless attachment.exists?(params[:style])
        end

        send_file attachment.path(params[:style]), :disposition => 'inline', :type => attachment.content_type
      end

      def id_from_partition(partition)
        partition.gsub('/', '').to_i
      end
  end
end