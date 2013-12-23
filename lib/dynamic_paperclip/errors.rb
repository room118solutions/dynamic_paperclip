module DynamicPaperclip
  class Error < StandardError
  end

  module Errors
    class SecretNotSet < DynamicPaperclip::Error
    end

    class InvalidHash < DynamicPaperclip::Error
    end
  end
end