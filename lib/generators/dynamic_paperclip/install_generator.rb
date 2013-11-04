module DynamicPaperclip
  class InstallGenerator < Rails::Generators::Base
    def create_initializer_file
      create_file 'config/initializers/dynamic_paperclip.rb' do
        <<-init
DynamicPaperclip.config.secret = '#{SecureRandom.urlsafe_base64(50)}'
init
      end
    end
  end
end