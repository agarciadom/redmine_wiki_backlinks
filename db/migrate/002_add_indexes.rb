class AddIndexes < ActiveRecord::Migration
  def change
    add_index :wiki_links, [:wiki_id, :from_page_id]
    add_index :wiki_links, [:wiki_id, :to_page_name]
  end
end
