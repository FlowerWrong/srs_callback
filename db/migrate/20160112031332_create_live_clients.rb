class CreateLiveClients < ActiveRecord::Migration[5.0]
  def change
    create_table :live_clients do |t|
      t.integer :client_id
      t.string :ip
      t.string :vhost
      t.string :app
      t.string :stream
      t.string :tc_url
      t.integer :status

      t.timestamps
    end
  end
end
