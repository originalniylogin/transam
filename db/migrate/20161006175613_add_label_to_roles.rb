class AddLabelToRoles < ActiveRecord::Migration[5.2]
  def change
    add_column :roles, :label, :string
  end
end
