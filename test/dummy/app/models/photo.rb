class Photo < ActiveRecord::Base
  has_dynamic_attached_file :image, styles: { thumb: '100x100#' }
  do_not_validate_attachment_file_type :image
end
