# -*- ruby -*-

require 'set'

class WikiLink < ActiveRecord::Base
  unloadable

  belongs_to :wiki
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'from_page_id'

  validates_presence_of :wiki_id, :from_page_id, :to_page_title

  def self.update_from_content(content)
    page = content.page
    wiki = page.wiki
    update_from_full(wiki, page, content)
  end

  def self.update_from_full(wiki, page, content)
    remove_from_page(page)
    add_from_page(wiki, page, content)
  end

  def self.add_from_page(wiki, page, content)
    linked_pages = collect_links(content.text)
    linked_pages.each do |p|
      link = WikiLink.new(:wiki => wiki,
                          :page => page,
                          :to_page_title => Wiki.titleize(p))
      link.save or raise "Could not save link from #{page.title} to #{p}"
    end
  end

  def self.remove_from_page(page)
    page.links_from.destroy_all
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
