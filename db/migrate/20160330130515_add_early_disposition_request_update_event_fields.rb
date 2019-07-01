class AddEarlyDispositionRequestUpdateEventFields < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_events, :state, :string, limit: 32 
    add_column :asset_events, :document, :string, limit: 128
    add_column :asset_events, :original_filename, :string, limit: 128
  end
end
