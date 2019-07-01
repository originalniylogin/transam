class CreateUserNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :user_notifications do |t|
      t.references :user,           null: false, index: true
      t.references :notification,   null: false, index: true
      t.datetime :opened_at

      t.timestamps
    end
  end
end
