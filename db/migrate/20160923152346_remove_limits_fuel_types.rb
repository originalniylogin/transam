class RemoveLimitsFuelTypes < ActiveRecord::Migration[5.2]
  def change
    change_column :fuel_types, :name, :string, :limit => nil
    change_column :fuel_types, :code, :string, :limit => nil
    change_column :fuel_types, :description, :string, :limit => nil
  end
end
