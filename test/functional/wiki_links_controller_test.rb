require File.expand_path('../../test_helper', __FILE__)

class WikiLinksControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules,
           :users, :members, :member_roles, :roles

  def setup
    @project = Project.find(1)
    @wiki = Wiki.new(:project => Project.find(1))
    @wiki.start_page = 'Wiki'
    assert @wiki.save

    @project.wiki = @wiki
    assert @project.save

    @page = add_page @wiki, @wiki.start_page
  end

  def test_links_from_noauth_login
    get :links_from, { :project_id => @project.id, :page_id => @page.title }

    # user is sent to /login
    assert_response :redirect
  end

  def test_links_from_auth_forbidden
    login_as "jsmith"
    get :links_from, {:project_id => @project.id, :page_id => @page.title }
    assert_response 403
  end

  def test_links_from_noauth_public_empty
    role_allow "Anonymous", :view_wiki_links

    get :links_from, {
      :project_id => @project.id,
      :page_id => @page.title
    }

    assert_response :success
    assert_equal assigns(:link_pages), []
    assert_select "p.nodata", 1
  end

  def test_links_from_noauth_public_missing_project
    role_allow "Anonymous", :view_wiki_links
    get :links_from, {:project_id => 'missing', :page_id => @page.title }
    assert_response :missing
  end

  def test_links_from_noauth_public_missing_page
    role_allow "Anonymous", :view_wiki_links
    get :links_from, {:project_id => @project.id, :page_id => 'Missing'}
    assert_response :missing
  end

  def test_links_from_noauth_public_two
    login_as "jsmith"
    role_allow "Manager", :view_wiki_links
    update_page @page, "[[A page]]\nAnother [[Page]]"

    get :links_from, {
      :project_id => @project.id,
      :page_id => @page.title
    }

    assert_response :success
    assert_equal ["A_page", "Page"], assigns(:link_pages)
    assert_select "ul.wiki_links > li", 2
  end

  def test_links_to_noauth_login
    get :links_to, {
      :project_id => @project.id,
      :page_id => @page.title
    }

    assert_response :redirect
  end

  def test_links_to_auth_forbidden
    login_as "jsmith"

    get :links_to, {
      :project_id => @project.id,
      :page_id => @page.title
    }

    assert_response 403
  end

  def test_links_to_noauth_public_empty
    role_allow "Anonymous", :view_wiki_links

    get :links_to, {
      :project_id => @project.id,
      :page_id => @page.title
    }

    assert_response :success
    assert_equal [], assigns(:link_pages)
    assert_select "p.nodata", 1
  end

  def test_links_to_noauth_public_missing_project
    role_allow "Anonymous", :view_wiki_links
    get :links_to, {:project_id => 'missing', :page_id => @page.title}
    assert_response :missing
  end

  def test_links_to_noauth_public_missing_page
    role_allow "Anonymous", :view_wiki_links
    get :links_to, {:project_id => @project.id, :page_id => 'Missing'}
    assert_response :missing
  end

  def test_links_to_noauth_public_empty
    role_allow "Manager", :view_wiki_links
    login_as "jsmith"

    update_page @page, 'Link to [[another page]]'
    new_page = add_page @wiki, 'Another_page'

    get :links_to, {
      :project_id => @project.id,
      :page_id => new_page.title
    }

    assert_response :success
    assert_equal [@page.title], assigns(:link_pages)
    assert_select "ul.wiki_links > li", 1
  end

  def test_orphan_noauth_login
    get :orphan, :project_id => @project.id
    assert_response :redirect
  end

  def test_orphan_auth_forbidden
    login_as "jsmith"
    get :orphan, :project_id => @project.id
    assert_response 403
  end

  def test_orphan_noauth_public_empty
    role_allow "Anonymous", :view_wiki_links
    get :orphan, :project_id => @project.id

    assert_response :success
    assert_equal [], assigns(:link_pages)
    assert_select "p.nodata", 1
  end

  def test_orphan_noauth_public_missing_project
    role_allow "Anonymous", :view_wiki_links
    get :orphan, :project_id => 'Missing'
    assert_response :missing
  end

  def test_orphan_auth_notempty
    role_allow "Manager", :view_wiki_links
    login_as "jsmith"
    add_page @wiki, 'Orphan'

    get :orphan, :project_id => @project.id

    assert_response :success
    assert_equal ["Orphan"], assigns(:link_pages)
    assert_select "ul.wiki_links > li", 1
  end

  def test_wanted_noauth_login
    get :wanted, :project_id => @project.id
    assert_response :redirect
  end

  def test_wanted_auth_forbidden
    login_as "jsmith"
    get :wanted, :project_id => @project.id
    assert_response 403
  end

  def test_wanted_noauth_public_empty
    role_allow "Anonymous", :view_wiki_links
    get :wanted, :project_id => @project.id
    assert_response :success
    assert_equal [], assigns(:link_pages)
    assert_select "p.nodata", 1
  end

  def test_wanted_noauth_public_missing_project
    role_allow "Anonymous", :view_wiki_links
    get :wanted, :project_id => 'Missing'
    assert_response :missing
  end

  def test_wanted_auth_notempty
    role_allow "Manager", :view_wiki_links
    login_as "jsmith"
    update_page @page, 'This page should link to [[something]]'

    get :wanted, :project_id => @project.id
    assert_response :success
    assert_equal ["Something"], assigns(:link_pages)
    assert_select "ul.wiki_links > li", 1
  end

  def test_index_noauth_login
    get :index
    assert_response :redirect
  end

  def test_index_notadmin_forbidden
    login_as "jsmith"
    get :index
    assert_response 403
  end

  def test_index_admin_empty
    @wiki.destroy

    login_as "admin"
    get :index
    assert_response :success
    assert_equal [], assigns(:project_wikis)
    assert_select "p.nodata", 1
  end

  def test_index_admin_one
    login_as "admin"
    get :index
    assert_response :success
    assert_equal [{"wiki_id" => @wiki.id, "project_name" => @project.name}], assigns(:project_wikis)
    assert_select "#projectwikis-form label", 1
  end

  # PRIVATE ####################################################################

  def login_as(login)
    uid = User.find_by_login(login).id
    @request.session[:user_id] = uid or raise "No user with name '#{name}'"
  end

  def role_allow(role_name, permission)
    Role.find_by_name(role_name).add_permission! permission
  end

end
