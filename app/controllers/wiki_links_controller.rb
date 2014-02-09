class WikiLinksController < ApplicationController
  unloadable
  menu_item :wiki

  def links_from
    @project = Project.find(params[:project_id])
    @page = @project.wiki.pages.find_by_title(params[:page_id])
  end

  def links_to
    @project = Project.find(params[:project_id])
    @page = @project.wiki.pages.find_by_title(params[:page_id])
  end

  def orphan
    @project = Project.find(params[:project_id])
  end

  def wanted
    @project = Project.find(params[:project_id])
  end
end
