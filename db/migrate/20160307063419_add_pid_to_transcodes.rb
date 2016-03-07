class AddPidToTranscodes < ActiveRecord::Migration[5.0]
  def change
    add_column :transcodes, :pid, :string
  end
end
