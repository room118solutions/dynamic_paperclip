module DynamicPaperclip
  class Error < StandardError
  end

  module Errors
    class UndefinedAttachment < DynamicPaperclip::Error
    end

    class MissingID < DynamicPaperclip::Error
    end

    class SecretNotSet < DynamicPaperclip::Error
    end

    class InvalidHash < DynamicPaperclip::Error
    end
  end
end