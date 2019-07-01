class AddDelayedJobPriorities < ActiveRecord::Migration[5.2]
  def change
    create_table :delayed_job_priorities do |t|
      t.string :class_name,     null: false
      t.integer :priority,      null: false

      t.timestamps
    end
  end
end
