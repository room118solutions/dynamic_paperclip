require 'paperclip'
require "dynamic_paperclip/errors"
require "dynamic_paperclip/config"
require "dynamic_paperclip/engine"
require "dynamic_paperclip/attachment"
require "dynamic_paperclip/has_attached_file"
require "dynamic_paperclip/paperclip_shim"
require "dynamic_paperclip/url_security"

module DynamicPaperclip
  extend self

  def config
    @@config ||= Config.new
  end
end
