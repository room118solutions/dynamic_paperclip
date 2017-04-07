require 'test_helper'

class Foo < ActiveRecord::Base; end

class HasAttachedFileTest < MiniTest::Unit::TestCase
  should 'register dynamic attachment' do
    DynamicPaperclip::AttachmentRegistry.expects(:register).with(Foo, :bar, { url: '/system/foos/bars/:id_partition/:style/:filename' })

    DynamicPaperclip::HasAttachedFile.define_on Foo, :bar, { url: '/system/foos/bars/:id_partition/:style/:filename' }
  end
end