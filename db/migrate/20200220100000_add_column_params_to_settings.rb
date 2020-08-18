class AddColumnParamsToSettings < ActiveRecord::Migration[5.2]
  def change
    change_table :gantt_issue_settings do |t|
      t.text :column_names, limit: 16384
      t.text :query_params, limit: 16384 #, default: '{}'
    end
  end
end
