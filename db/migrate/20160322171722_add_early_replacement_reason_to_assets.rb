class AddEarlyReplacementReasonToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :early_replacement_reason, :text, after: :scheduled_replacement_cost
  end
end
