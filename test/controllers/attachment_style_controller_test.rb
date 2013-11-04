require 'test_helper'

class Foo < ActiveRecord::Base
  has_dynamic_attached_file :image,
    :url    => '/system/:class/:attachment/:id/:style/:filename',
    :styles => {
      :thumb => '50x50#'
    }

  has_dynamic_attached_file :image_with_id_partition_in_url,
    :url => '/system/:class/:attachment/:id_partition/:style/:filename'
end

class DynamicPaperclip::AttachmentStylesControllerTest < ActionController::TestCase
  setup do
    @foo = stub('foo')
    @attachment = stub('image attachment', :path => File.join(FIXTURES_DIR, 'rails.png'), :content_type => 'image/jpeg')

    Foo.stubs(:find).with('1').returns @foo
    @foo.stubs(:image).returns @attachment
  end

  should 'raise error if attachment is not defined on class' do
    assert_raises(DynamicPaperclip::Errors::UndefinedAttachment) {
      get :generate_foo,
          :attachment => 'bars',
          :id         => '1',
          :style      => 'style',
          :filename   => 'file',
          :use_route  => :dynamic_paperclip_engine
    }
  end

  should 'raise error if no ID is given' do
    assert_raises(DynamicPaperclip::Errors::MissingID) {
      get :generate_foo,
          :attachment => 'images',
          :style      => 'style',
          :filename   => 'file',
          :use_route  => :dynamic_paperclip_engine
      }
  end

  should 'not process style if it is not dynamic' do
    @attachment.expects(:process_dynamic_style).never

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'thumb',
        :filename   => 'file',
        :use_route  => :dynamic_paperclip_engine
  end

  should 'not process style if it is dynamic but already exists' do
    @attachment.expects(:exists?).with('dynamic_42x42').returns(true)
    @attachment.expects(:process_dynamic_style).never

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'dynamic_42x42',
        :filename   => 'file',
        :s          => DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42'),
        :use_route  => :dynamic_paperclip_engine
  end

  should 'process style if it is dynamic and does not exist' do
    @attachment.expects(:exists?).with('dynamic_42x42').returns(false)
    @attachment.expects(:process_dynamic_style).once

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'dynamic_42x42',
        :filename   => 'file',
        :s          => DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42'),
        :use_route  => :dynamic_paperclip_engine
  end

  should 'find record when an ID is used' do
    Foo.expects(:find).with('1').returns @foo

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'thumb',
        :filename   => 'file',
        :use_route  => :dynamic_paperclip_engine
  end

  should 'find record when an ID partition is used' do
    @foo.stubs(:image_with_id_partition_in_url).returns @attachment
    Foo.expects(:find).with(10042).returns @foo

    get :generate_foo,
        :attachment   => 'image_with_id_partition_in_urls',
        :id_partition => '000/010/042',
        :style        => 'thumb',
        :filename     => 'file',
        :use_route    => :dynamic_paperclip_engine
  end

  should 'respond with correct content type' do
    @attachment.stubs(:exists?).returns(true)

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'dynamic_42x42',
        :filename   => 'file',
        :s          => DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42'),
        :use_route  => :dynamic_paperclip_engine

    assert_equal 'image/jpeg', @response.header['Content-Type']
  end

  should 'send image to client with correct content type and disposition' do
    @attachment.stubs(:exists?).returns(true)

    @controller.stubs(:render)
    @controller.expects(:send_file).with(@attachment.path, :disposition => 'inline', :type => @attachment.content_type)

    get :generate_foo,
        :attachment => 'images',
        :id         => '1',
        :style      => 'dynamic_42x42',
        :filename   => 'file',
        :s          => DynamicPaperclip::UrlSecurity.generate_hash('dynamic_42x42'),
        :use_route  => :dynamic_paperclip_engine
  end

  should 'raise error if hash does not match style name' do
    assert_raises(DynamicPaperclip::Errors::InvalidHash) do
      get :generate_foo,
          :attachment => 'images',
          :id         => '1',
          :style      => 'dynamic_42x42',
          :filename   => 'file',
          :s          => 'this is an invalid hash',
          :use_route  => :dynamic_paperclip_engine
      end
  end
end