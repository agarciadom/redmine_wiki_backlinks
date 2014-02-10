require File.expand_path('../../test_helper', __FILE__)

class WikiLinkTest < ActiveSupport::TestCase
  fixtures :projects, :enabled_modules,
           :users, :members, :member_roles, :roles,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions

  def setup
    @wiki = Wiki.find(1)
    @page = @wiki.pages.first
  end

  # Creation of instances

  def test_no_links_by_default
    assert WikiLink.all.empty?
  end

  def test_empty_link_is_rejected
    l = WikiLink.new
    assert l.invalid?, "Link with no information should be rejected"
  end

  def test_link_without_wiki_is_rejected
    l = WikiLink.new(:page => @page, :to_page_title => 'Example')
    assert l.invalid?, "Link with no wiki should be rejected"
  end

  def test_link_without_source_is_rejected
    l = WikiLink.new(:wiki => @wiki, :to_page_title => 'Example')
    assert l.invalid?, "Link with no source page should be rejected"
  end

  def test_link_without_target_is_rejected
    l = WikiLink.new(:wiki => @wiki, :page => @page)
    assert l.invalid?, "Link with no target page should be rejected"
  end

  def test_valid_link
    l = WikiLink.new(:wiki => @wiki, :page => @page, :to_page_title => 'Example')
    assert l.save, "Valid link can be saved"
  end

  # Link collection

  def test_collect_links_empty
    assert_links_equal [], ""
  end

  def test_collect_links_one
    assert_links_equal ["X"], "[[X]]"
  end

  def test_collect_links_one_alt
    assert_links_equal ["X"], "[[X|Some text]]"
  end

  def test_collect_links_one_crossproject1
    assert_links_equal [], "[[sandbox:X]]"
  end

  def test_collect_links_one_crossproject2
    assert_links_equal [], "[[sandbox:X]]"
  end

  def test_collect_links_one_escaped
    assert_links_equal [], "![[X]]"
  end

  def test_collect_links_two_diff
    assert_links_equal ["X", "Y"], "[[X]] [[Y]]"
  end

  def test_collect_links_two_same
    assert_links_equal ["X"], "[[X]] [[X]]"
  end

  def assert_links_equal(expected, text)
    assert_equal WikiLink.collect_links(text), expected.to_set
  end

  # Link population and removal (manual and using the Rails callbacks)

  def test_populate_remove_manual
    @page = WikiPage.find(1)
    WikiLink.update_from_content(@page.content)
    assert_equal @page.wiki_links.first.to_page_title, "Documentation"

    WikiLink.remove_from_page(@page)
    assert @page.wiki_links.all.empty?
  end

  def test_populate_destroy_page_auto
    # Create a new wiki page with a link
    new_page = WikiPage.new(:wiki => @wiki, :title => 'New_page')
    new_content = WikiContent.new(:page => new_page,
                                  :text => 'This is a [[new link]]')
    assert new_content.save

    # A new link should have been created
    assert_equal new_page.wiki_links.first.to_page_title, "New_link"
    assert !WikiLink.where(:from_page_id => new_page.id).all.empty?

    # After the page is destroyed, the link should not exist anymore
    new_page.destroy
    assert WikiLink.where(:from_page_id => new_page.id).all.empty?
  end

  def test_populate_destroy_content_auto
    # Create a new wiki page with a link
    new_page = WikiPage.new(:wiki => @wiki, :title => 'New_page')
    new_content = WikiContent.new(:page => new_page,
                                  :text => 'This is a [[new link]]')
    assert new_content.save

    # A new link should have been created
    assert_equal new_page.wiki_links.first.to_page_title, "New_link"
    assert !WikiLink.where(:from_page_id => new_page.id).all.empty?

    # After the page is destroyed, the link should not exist anymore
    new_content.destroy
    assert WikiLink.where(:from_page_id => new_page.id).all.empty?
  end

  def test_populate_update_content_auto
    # Create a new wiki page with a link
    new_page = WikiPage.new(:wiki => @wiki, :title => 'New_page')
    new_content = WikiContent.new(:page => new_page,
                                  :text => 'This is a [[new link]]')
    assert new_content.save

    # Change the content and save
    new_content.text = "Here is [[another link]]"
    assert new_content.save

    # There should only be the new link
    assert_equal new_page.wiki_links.first.to_page_title,
                 "Another_link", "There should only be the new link"
  end

end
