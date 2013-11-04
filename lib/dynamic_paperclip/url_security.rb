module DynamicPaperclip
  class UrlSecurity
    def self.generate_hash(style_name)
      Digest::SHA1.hexdigest "#{DynamicPaperclip.config.secret}#{style_name}"
    end

    def self.valid_hash?(hash, style_name)
      generate_hash(style_name) == hash
    end
  end
end