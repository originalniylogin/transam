class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.string :object_key,     limit: 12, null: false
      t.string :text,           null: false
      t.string :link,           null: false
      t.references :notifiable, polymorphic: true, index: true
      t.boolean :active

      t.timestamps
    end
  end
end
