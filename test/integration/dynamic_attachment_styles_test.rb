require 'test_helper'

class DynamicAttachmentStylesTest < ActionDispatch::IntegrationTest
  fixtures :photos

  should 'generate dynamic style and send it to the client' do
    path_to_dynamic_style = Photo.find(1).image.path('dynamic_100x100')

    # This style should not exist yet
    assert !File.exists?(path_to_dynamic_style)

    # The style should be created right now
    get '/system/photos/images/000/000/001/dynamic_100x100/rails.png'

    assert_response :success
    assert_equal 'image/png', @response.headers['Content-Type']

    # Make sure we respond with the style that previously did not exist
    assert FileUtils.compare_stream StringIO.new(@response.body), open(path_to_dynamic_style)

    # Clean up dynamic style we just created
    FileUtils.rm_rf File.dirname path_to_dynamic_style
  end
end