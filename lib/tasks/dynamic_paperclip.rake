namespace :dynamic_paperclip do
  desc 'Removes the given dynamic DEFINITION from the given CLASS and ATTACHMENT'
  task :remove_style => :environment do
    class_name      = ENV['CLASS'] || ENV['class']
    attachment_name = ENV['ATTACHMENT'] || ENV['attachment']
    definition      = ENV['DEFINITION'] || ENV['definition']

    raise 'must specify a DEFINITION'   unless definition.present?
    raise 'must specify a CLASS'        unless class_name.present?
    raise 'must specify an ATTACHMENT'  unless attachment_name.present?

    raise "'#{attachment_name}' is not a dynamic attachment on the #{class_name} class" unless DynamicPaperclip::AttachmentRegistry.names_for(class_name.constantize).include?(attachment_name.to_sym)

    total_deletes = 0

    Paperclip.each_instance_with_attachment(class_name, attachment_name) do |instance|
      attachment = instance.send(attachment_name)
      style_name = DynamicPaperclip::StyleNaming.dynamic_style_name_from_definition(definition)

      # Only proceed if this attachment has generated the given definition
      if attachment.dynamic_styles.keys.include?(style_name)
        total_deletes += 1

        puts "Deleting: #{attachment.path(style_name)}"

        attachment.delete_styles style_name
      end
    end

    puts "**Deleted #{total_deletes} instances of the '#{definition}' dynamic style for the #{class_name} #{attachment_name} attachment**"
  end
end