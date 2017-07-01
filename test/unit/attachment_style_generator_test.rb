require 'test_helper'

class Foo < ActiveRecord::Base
  has_dynamic_attached_file :image,
    :url    => '/system/:class/:attachment/:id/:style/:filename'

  has_dynamic_attached_file :image_with_id_partition_in_url,
    :url => '/system/:class/:attachment/:id_partition/:style/:filename'
end

class DynamicPaperclip::AttachmentStyleGeneratorTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    DynamicPaperclip::AttachmentStyleGenerator.new(@app)
  end

  def setup
    @app = stub('Application', :call => [200, {}, ''])

    @foo = stub('foo')
    @attachment = stub('image attachment', :path => File.join(FIXTURES_DIR, 'rails.png'), :content_type => 'image/jpeg')
    @attachment.stubs(:exists?).returns(true)

    Foo.stubs(:find).with(1).returns @foo
    @foo.stubs(:image).returns @attachment
  end

  should 'not process style if it already exists' do
    @attachment.expects(:exists?).with(:dynamic_42x42).returns(true)
    @attachment.expects(:process_dynamic_style).never

    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }
  end

  should 'process style if it is dynamic and does not exist' do
    @attachment.expects(:exists?).with(:dynamic_42x42).returns(false)
    @attachment.expects(:process_dynamic_style).once

    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }
  end

  should 'find record when an ID is used' do
    Foo.expects(:find).with(1).returns @foo

    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }
  end

  should 'find record when an ID partition is used' do
    @foo.stubs(:image_with_id_partition_in_url).returns @attachment
    Foo.expects(:find).with(10042).returns @foo

    get '/system/foos/image_with_id_partition_in_urls/000/010/042/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }
  end

  should 'respond with correct content type' do
    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }

    assert_equal 'image/jpeg', last_response.header['Content-Type']
  end

  should 'respond with correct content-disposition' do
    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }

    assert_equal 'inline; filename=rails.png', last_response.header['Content-Disposition']
  end

  should 'respond with correct content-transfer-encoding' do
    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }

    assert_equal 'binary', last_response.header['Content-Transfer-Encoding']
  end

  should 'respond with FileBody' do
    file_body = ActionDispatch::Response::FileBody.new(File.join(FIXTURES_DIR, 'rails.png'))
    ActionDispatch::Response::FileBody.expects(:new).with(File.join(FIXTURES_DIR, 'rails.png')).returns(file_body)

    response = app.call(Rack::MockRequest.env_for('/system/foos/images/1/dynamic_42x42/file?s='+DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42')))

    assert_equal file_body, response[2]
  end

  should 'respond with success' do
    get '/system/foos/images/1/dynamic_42x42/file', { s: DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42') }

    assert last_response.ok?
  end

  should '403 with empty body if hash does not match style name' do
    get '/system/foos/images/1/dynamic_42x42/file', { s: 'this is an invalid hash' }

    assert_equal 403, last_response.status
    assert_equal '', last_response.body
  end
end
