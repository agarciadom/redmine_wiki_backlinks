# -*- ruby -*-

require 'set'

class WikiLink < ActiveRecord::Base
  unloadable
  belongs_to :wiki
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'from_page_id'
  validates_presence_of :to_page_name

  def self.update_from_content(content)
    page = content.page
    wiki = page.wiki

    # Remove the existing links and recreate from all the links we found now
    linked_pages = collect_links(content.text)
    remove_from_content(content)
    linked_pages.each do |p|
      link = WikiLink.new(:wiki_id => wiki.id,
                          :from_page_id => page.id,
                          :to_page_name => Wiki.titleize(p))
      link.save
    end
  end

  def self.remove_from_content(content)
    page = content.page
    delete_all(["from_page_id = ?", page.id])
  end

  def self.collect_links(text)
    # Returns a set with the page names for all the local links in the text.
    # Based on redmine/app/helper/application_helper.rb#parse_wiki_links

    set_pages = Set.new
    text.scan(/(!)?(\[\[([^\]\n\|]+)(\|([^\]\n\|]+))?\]\])/) do |m|
      esc, all, page, title = $1, $2, $3, $5
      if esc.nil?
        if page =~ /^([^\:]+)\:(.*)$/
          # Skip cross-project links
          next
        end

        # extract anchor
        anchor = nil
        if page =~ /^(.+?)\#(.+)$/
          page, anchor = $1, $2
        end

        set_pages.add(page)
      end
    end

    set_pages
  end
end
