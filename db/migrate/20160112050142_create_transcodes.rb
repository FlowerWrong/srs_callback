class CreateTranscodes < ActiveRecord::Migration[5.0]
  def change
    create_table :transcodes do |t|
      t.integer :live_client_id
      t.string :input_rtmp
      t.string :output_rtmp
      t.string :ip
      t.string :vhost
      t.string :app
      t.string :stream
      t.integer :status
      t.integer :pid

      t.timestamps
    end
  end
end
