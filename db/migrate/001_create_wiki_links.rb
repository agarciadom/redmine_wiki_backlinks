class CreateWikiLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :wiki_links do |t|
      t.integer :wiki_id, :null => false
      t.integer :from_page_id, :null => false
      t.string :to_page_title, :null => false
    end
  end
end
