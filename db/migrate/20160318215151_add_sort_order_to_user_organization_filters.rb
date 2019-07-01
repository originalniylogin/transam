class AddSortOrderToUserOrganizationFilters < ActiveRecord::Migration[5.2]
  def change
    if ActiveRecord::Base.connection.table_exists?(:user_organization_filters)
      add_column :user_organization_filters, :sort_order, :integer 
    end
  end
end
