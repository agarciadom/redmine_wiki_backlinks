module WikiLinksWikiPagePatch
  # Patches Redmine's WikiPage model to make it more convenient
  # to access the outgoing links from a wiki page.

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      has_many :wiki_links, :foreign_key => 'from_page_id'
      after_destroy :remove_wiki_links
    end
  end

  module InstanceMethods
    def remove_wiki_links
      WikiLink.remove_from_page(self)
    end
  end

end
