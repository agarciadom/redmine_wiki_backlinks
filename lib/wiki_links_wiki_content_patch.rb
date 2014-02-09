module WikiLinksWikiContentPatch
  # Patches Redmine's WikiContent model to keep the WikiLinks models up to date.
  # Largely based on code from WikiNG and Eric Davis' Kanban plugin'.

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      after_save :update_wiki_links
      after_destroy :remove_wiki_links
    end
  end

  module InstanceMethods
    def update_wiki_links
      WikiLink.update_from_content(self)
    end

    def remove_wiki_links
      WikiLink.remove_from_content(self)
    end
  end

end
