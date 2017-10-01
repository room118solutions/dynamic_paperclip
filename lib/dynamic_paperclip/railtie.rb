require 'dynamic_paperclip/attachment_style_generator'

module DynamicPaperclip
  class Railtie < Rails::Railtie
    initializer 'dynamic_paperclip.insert_middleware' do |app|
      app.config.middleware.use DynamicPaperclip::AttachmentStyleGenerator
    end

    rake_tasks { load 'tasks/dynamic_paperclip.rake' }
  end
end
