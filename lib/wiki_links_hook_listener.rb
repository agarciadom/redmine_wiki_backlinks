class WikiLinksHookListener < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
    stylesheet_link_tag "wiki_links", :plugin => :wiki_links
  end
end
