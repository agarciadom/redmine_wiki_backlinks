# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def add_page(wiki, title, text="h1. #{title}\nEmpty page.")
  p = WikiPage.new(:wiki => wiki, :title => title)
  c = WikiContent.new(:page => p, :text => text)
  p.save_with_content(c) or raise "Could not add page #{title}"
  p
end

def update_page(page, text)
  page.content.text = text
  page.content.save
  page
end
