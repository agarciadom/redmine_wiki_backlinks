class WikiLink < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'page_id'
  validates_presence_of :to_page_name
end
