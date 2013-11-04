require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  fixtures :photos

  should 'use DynamicPaperclip::Attachment for dynamic attachments' do
    assert Photo.new.image.is_a?(DynamicPaperclip::Attachment)
  end

  should 'generate correct secure attachment URL when given a style definition' do
    DynamicPaperclip::Config.any_instance.stubs(:secret).returns('abc123')

    assert_equal "/system/photos/images/000/000/001/dynamic_50x50%2523/rails.png?s=#{Digest::SHA1.hexdigest("abc123dynamic_50x50%23")}", photos(:rails).image.dynamic_url('50x50#')
  end

  should 'raise error if no secret has been configured' do
    DynamicPaperclip::Config.any_instance.stubs(:secret).returns(nil)

    assert_raises(DynamicPaperclip::Errors::SecretNotSet) { photos(:rails).image.dynamic_url('50x50#') }
  end

  should 'include existing dynamic styles in #styles' do
    assert photos(:rails).image.styles.has_key?(:thumb)
    assert photos(:rails).image.styles.has_key?(:dynamic_42x42)
  end

  should 'only include dynamic styles in #dynamic_styles' do
    assert photos(:rails).image.dynamic_styles.has_key?(:dynamic_42x42)
    assert !photos(:rails).image.dynamic_styles.has_key?(:thumb)
  end

  should 'add dynamic style to #styles and reprocess it when a dynamic style name is passed to #process_dynamic_style' do
    attachment = photos(:rails).image

    attachment.expects(:reprocess!).with('dynamic_42x42').once

    attachment.process_dynamic_style 'dynamic_42x42'

    assert_equal '42x42', attachment.styles[:dynamic_42x42].geometry
  end
end