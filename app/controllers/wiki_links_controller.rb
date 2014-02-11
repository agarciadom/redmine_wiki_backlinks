require 'set'

class WikiLinksController < ApplicationController
  unloadable

  default_search_scope :wiki_pages
  menu_item :wiki

  before_filter :find_wiki, :except => [:index, :parse]
  before_filter :find_existing_page, :only => [:links_from, :links_to]
  before_filter :authorize, :except => [:index, :parse]
  before_filter :require_admin, :only => [:index, :parse]

  def index
    @project_wikis = Wiki.joins(:project)
      .select(["wikis.id", "projects.name"])
      .collect{|x| {"wiki_id" => x.id, "project_name" => x.name}}
  end

  def parse
    if params[:parse_wikis]
      wikis = Wiki.find(params[:parse_wikis])
      wikis.each do |w|
        w.parse_all_pages
      end

      flash[:notice] = l(:flash_parse_ok, :nwikis => wikis.size)
    else
      flash[:warning] = l(:flash_parse_none)
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = l(:flash_parse_notfound)
  ensure
    redirect_to url_for(:action => 'index')
  end

  def links_from
    @link_pages = @page.links_from.pluck(:to_page_title)
  end

  def links_to
    # Obtain the ids of all the pages that link to this one
    ids_to = @page.links_to.uniq.pluck(:from_page_id)

    # Collect the pretty and ugly titles and sort by pretty title
    @link_pages = WikiPage.select(:title).find(ids_to).map(&:title)
  end

  def orphan
    available = available_pages(@wiki)
    existing = existing_targets(@wiki)
    @link_pages = (available - existing).delete(@wiki.start_page).to_a
  end

  def wanted
    available = available_pages(@wiki)
    existing = existing_targets(@wiki)
    @link_pages = (existing - available).to_a
  end

  private

  def find_wiki
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_existing_page
    @page = @wiki.find_page(params[:page_id])
    if @page.nil?
      render_404
      return
    end
    if @wiki.page_found_with_redirect?
      redirect_to params.update(:page_id => @page.title)
    end
  end

  def available_pages(wiki)
    wiki.pages.select("DISTINCT title").map(&:title).to_set
  end

  def existing_targets(wiki)
    wiki.links.select(:to_page_title).uniq.map(&:to_page_title).to_set
  end

end
