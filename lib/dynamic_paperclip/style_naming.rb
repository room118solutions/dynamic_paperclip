module DynamicPaperclip
  module StyleNaming
    # Generate style name from style definition,
    # only supports strings at the moment
    def self.dynamic_style_name_from_definition(options, uri_escape=true)
      if options.is_a?(String)
        "dynamic_#{uri_escape ? CGI.escape(options) : options}".to_sym
      else
        raise 'Only String options are supported with dynamic attachments'
      end
    end

    # Reverse of #dynamic_style_name_from_definition,
    # given a dynamic style name, extracts the definition (style options)
    def self.style_definition_from_dynamic_style_name(name)
      CGI.unescape(name[8..-1]).split(/_/).first
    end
  end
end
