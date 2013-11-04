require 'test_helper'

class Foo; end

class HasAttachedFileTest < Test::Unit::TestCase
  should 'glob id_partition' do
    DynamicPaperclip::HasAttachedFile.new Foo, :bar, { url: '/system/foos/bars/:id_partition/:style/:filename' }

    assert Rails.application.routes.routes.any? do |route|
      route.path.spec == '/system/foos/bars/*id_partition/:style/:filename(.:format)'
    end
  end

  should 'interpolate :class' do
    DynamicPaperclip::HasAttachedFile.new Foo, :bar, { url: '/system/:class/bars/:id/:style/:filename' }

    assert Rails.application.routes.routes.any? do |route|
      route.path.spec == '/system/foos/bars/:id/:style/:filename(.:format)'
    end
  end

  should "use Paperclip's default URL if none is specified" do
    DynamicPaperclip::HasAttachedFile.new Foo, :bar, {}

    assert Rails.application.routes.routes.any? do |route|
      route.path.spec == '/system/foos/:attachment/*id_partition/:style/:filename(.:format)'
    end
  end
end