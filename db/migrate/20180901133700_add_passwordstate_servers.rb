class AddPasswordstateServers < ActiveRecord::Migration[5.1]
  def change
    create_table :passwordstate_servers do |t|
      t.string :name, null: false, unique: true
      t.string :description, limit: 255
      t.string :url, limit: 255
      t.string :api_type, limit: 12
      t.string :user, limit: 255
      t.text :password

      t.timestamps null: false
    end

    create_table :passwordstate_facets do |t|
      t.references :host, null: false, foreign_key: true, index: true, unique: true
      t.references :passwordstate_server, foreign_key: true, index: true

      t.timestamps null: false
    end
  end
end

