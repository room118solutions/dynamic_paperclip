require 'test_helper'

class DynamicAttachmentStylesTest < ActionDispatch::IntegrationTest
  fixtures :photos

  should 'generate dynamic style and send it to the client' do
    photo = photos(:rails)

    path_to_dynamic_style = photo.image.path('dynamic_100x100')

    # This style should not exist yet
    assert !File.exists?(path_to_dynamic_style), "style to be generated already exists"

    # The style should be created right now when we request it
    get photo.image.dynamic_url('100x100')

    assert_response :success
    assert_equal 'image/png', @response.headers['Content-Type']

    # Make sure we respond with the style that previously did not exist
    assert FileUtils.compare_stream StringIO.new(@response.body), open(path_to_dynamic_style)

    # Clean up dynamic style we just created
    FileUtils.rm_rf File.dirname path_to_dynamic_style
  end
end