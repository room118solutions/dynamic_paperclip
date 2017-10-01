module DynamicPaperclip
  class Attachment < Paperclip::Attachment
    attr_reader :dynamic_styles

    def initialize(name, instance, options = {})
      super

      @dynamic_styles = {}

      # Add existing dynamic styles
      if instance.persisted?
        # Could be nil if the attachment doesn't exist
        if path_with_wildcard
          style_position = path_with_wildcard.index('dynamic_*')

          dynamic_files do |file|
            style_name = file[style_position..-1].split('/').first

            # In the event that the style name is used as the filename,
            # we want to remove the extension for our style name
            add_dynamic_style! File.basename(style_name, File.extname(style_name))
          end
        end
      end
    end

    def styles
      super.merge dynamic_styles
    end

    def process_dynamic_style(style_name)
      @options[:preserve_files] = true
      add_dynamic_style! style_name
      reprocess! style_name
    end

    def dynamic_url(definition)
      raise DynamicPaperclip::Errors::SecretNotSet, "No secret has been configured. Please run the dynamic_paperclip:install generator." unless DynamicPaperclip.config.secret.present?

      style_name = StyleNaming.dynamic_style_name_from_definition(definition)

      url = url(style_name)

      delimiter_char = url.match(/\?/) ? '&' : '?'

      "#{url}#{delimiter_char}s=#{UrlSecurity.generate_hash(style_name)}"
    end

    # Immediately deletes given styles without impacting existing delete queue
    def delete_styles(*styles)
      old_delete_queue = @queued_for_delete

      @queued_for_delete = []
      queue_some_for_delete *styles
      flush_deletes

      @queued_for_delete = old_delete_queue
    end

    def delete_dynamic_files
      if !@options[:preserve_files] && path_with_wildcard
        dynamic_files.each do |file|
          FileUtils.rm(file) if File.exist?(file)
        end
      end
    end

    private

      def add_dynamic_style!(name)
        @dynamic_styles[name.to_sym] = Paperclip::Style.new(name, StyleNaming.style_definition_from_dynamic_style_name(name), self)
      end

      def dynamic_files
        Dir.glob(path_with_wildcard)
      end

      def path_with_wildcard
        dynamic_path = path('dynamic_*')
        dynamic_path = "#{dynamic_path.split(/dynamic_\*/).first}dynamic_*" if dynamic_path.present?
        return dynamic_path
      end
  end
end
