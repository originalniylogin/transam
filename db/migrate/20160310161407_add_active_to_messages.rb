class AddActiveToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column    :messages, :active, :boolean, :after => :body
  end
end
