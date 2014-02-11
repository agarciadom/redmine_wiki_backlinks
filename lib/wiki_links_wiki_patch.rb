module WikiLinksWikiPatch
  # Patches Redmine's Wiki model to make it more convenient to access
  # the outgoing links from a wiki.

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      has_many :links, :class_name => 'WikiLink', :foreign_key => 'wiki_id'
      after_destroy :remove_wiki_links
    end
  end

  module InstanceMethods
    def remove_wiki_links
      self.links.destroy_all
    end

    def parse_all_pages
      transaction do
        remove_wiki_links
        self.pages.all.each do |p|
          WikiLink.add_from_page(self, p, p.content)
        end
      end
    end
  end

end
