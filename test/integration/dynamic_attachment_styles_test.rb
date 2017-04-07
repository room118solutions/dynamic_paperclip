require 'test_helper'

class DynamicAttachmentStylesTest < ActionDispatch::IntegrationTest
  self.fixture_path = FIXTURES_DIR
  fixtures :photos

  should 'generate dynamic style and send it to the client' do
    photo = photos(:rails)

    path_to_dynamic_style = photo.image.path('dynamic_100x100')

    # Ensure dynamic style does not exist yet
    FileUtils.rm_rf File.dirname path_to_dynamic_style

    # The style should be created right now when we request it
    get photo.image.dynamic_url('100x100')

    assert_response :success
    assert_equal 'image/png', @response.headers['Content-Type']

    # Make sure new style was generated
    assert File.exist?(path_to_dynamic_style)

    # Clean up dynamic style we just created
    FileUtils.rm_rf File.dirname path_to_dynamic_style
  end
end