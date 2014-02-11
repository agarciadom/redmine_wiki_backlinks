require File.expand_path('../../test_helper', __FILE__)

class WikiLinkTest < ActiveSupport::TestCase
  fixtures :projects, :enabled_modules,
           :users, :members, :member_roles, :roles

  def setup
    @wiki = Wiki.new(:project => Project.find(1))
    @wiki.start_page = 'Wiki'
    assert @wiki.save

    @page = add_page @wiki, @wiki.start_page
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
    @page.content.text = 'Here is some [[documentation]]'
    WikiLink.update_from_content(@page.content)
    assert_equal @page.links_from.first.to_page_title, "Documentation"

    WikiLink.remove_from_page(@page)
    assert @page.links_from.all.empty?
  end

  def test_populate_destroy_page_auto
    # Create a new wiki page with a link
    new_page = WikiPage.new(:wiki => @wiki, :title => 'New_page')
    new_content = WikiContent.new(:page => new_page,
                                  :text => 'This is a [[new link]]')
    assert new_page.save_with_content(new_content)

    # Reload to pick up the information produced by the callbacks
    new_page.reload

    # A new link should have been created
    assert_equal new_page.links_from.first.to_page_title, "New_link"
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
    assert new_page.save_with_content(new_content)

    # Reload to pick up the information produced by the callbacks
    new_page.reload

    # A new link should have been created
    assert_equal new_page.links_from.first.to_page_title, "New_link"
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
    assert new_page.save_with_content(new_content)
    new_page.reload

    # Change the content, save and reload
    new_content.text = "Here is [[another link]]"
    assert new_content.save
    new_page.reload

    # There should only be the new link
    assert_equal new_page.links_from.first.to_page_title,
                 "Another_link", "There should only be the new link"
  end

end
