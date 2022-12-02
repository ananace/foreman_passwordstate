# frozen_string_literal: true

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
      t.references :passwordstate_server, null: false, foreign_key: true, index: { name: :idx_pwstate_host_by_pwstate_server }
      t.integer :host_id, null: false, index: true

      t.integer :password_list_id, null: false

      t.timestamps null: false
    end

    add_index :passwordstate_host_facets, %i[host_id passwordstate_server_id], name: 'idx_pwstate_host', unique: true

    create_table :passwordstate_hostgroup_facets do |t|
      t.references :passwordstate_server, null: false, foreign_key: true, index: { name: :idx_pwstate_hostgroup_by_pwstate_server }
      t.integer :hostgroup_id, null: false, index: true

      t.integer :password_list_id, null: false

      t.timestamps null: false
    end

    add_index :passwordstate_hostgroup_facets, %i[hostgroup_id passwordstate_server_id], name: 'idx_pwstate_hostgroup', unique: true
  end
end
