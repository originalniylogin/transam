class CreateOrganizationRoleMappings < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_role_mappings do |t|
      t.integer :organization_id, null: false
      t.integer :role_id, null: false

      t.timestamps
    end
  end
end
