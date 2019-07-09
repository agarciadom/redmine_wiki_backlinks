class AddIndexes < ActiveRecord::Migration[5.0]
  def change
    # By wiki, to find all the links in a wiki (useful for finding orphan or wanted pages)
    add_index :wiki_links, :wiki_id

    # By source page ID, to keep links up to date and find outgoing links
    add_index :wiki_links, :from_page_id

    # By wiki + destination page, for finding incoming links
    add_index :wiki_links, [:wiki_id, :to_page_title]
  end
end
