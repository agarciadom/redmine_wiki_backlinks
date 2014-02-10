class WikiLinksController < ApplicationController
  unloadable

  menu_item :wiki

  before_filter :find_project_by_project_id
  before_filter :authorize
  before_filter :only => [:links_from, :links_to, :orphan, :wanted]

  def links_from
    # Make sure this page exists
    @page = @project.wiki.pages.find_by_title(params[:page_id])

    # We prettify the title without loading the page itself,
    # and then sort by the pretty title.
    @link_pages = WikiLink.where(:from_page_id => @page.id)
                          .select(:to_page_name)
                          .all
                          .collect{|x| _title_versions(x[:to_page_name])}
                          .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  def links_to
    # Make sure this page exists
    @page = @project.wiki.pages.find_by_title(params[:page_id])

    # Obtain the ids of all the pages that link to this one
    ids_to = WikiLink.where(:wiki_id => @project.wiki.id)
                     .where(:to_page_name => Wiki.titleize(@page.title))
                     .select(:from_page_id)
                     .all
                     .collect{|x| x[:from_page_id]}

    # Remove repetitions
    ids_to = Set.new(ids_to).to_a

    # Collect the pretty and ugly titles and sort by pretty title
    @link_pages = WikiPage.select(:title)
                          .find(ids_to)
                          .collect{|x| _title_versions(x.title)}
                          .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  def orphan
    # nothing for now!
  end

  def wanted
    # nothing for now!
  end

  def _title_versions(title)
    { :pretty => title.tr('_', ' '), :ugly => title }
  end
end
