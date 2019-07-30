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
      t.references :passwordstate_server, null: false, foreign_key: true

      t.integer :host_id
      t.integer :hostgroup_id
      t.integer :password_list_id, null: false

      t.timestamps null: false
    end

    add_index :passwordstate_facets, [:host_id, :passwordstate_server_id], name: 'idx_pwstate_host', unique: true
    add_index :passwordstate_facets, [:hostgroup_id, :passwordstate_server_id], name: 'idx_pwstate_hostgroup', unique: true
  end
end
