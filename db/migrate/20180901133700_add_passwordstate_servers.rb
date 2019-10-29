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

    create_table :passwordstate_host_facets do |t|
      t.references :passwordstate_server, null: true, index: false, foreign_key: true
      t.integer :host_id, null: false, index: true, unique: true

      t.integer :password_list_id, null: true

      t.timestamps null: false
    end

    create_table :passwordstate_hostgroup_facets do |t|
      t.references :passwordstate_server, null: true, index: false, foreign_key: true
      t.integer :hostgroup_id, null: false, index: true, unique: true

      t.integer :password_list_id, null: true

      t.timestamps null: false
    end
  end
end
