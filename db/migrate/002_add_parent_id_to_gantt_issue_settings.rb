class GanttIssueSetting < ActiveRecord::Base; end

class AddParentIdToGanttIssueSettings < ActiveRecord::Migration[4.2]
  # def change
  #   add_column :gantt_issue_settings, :parent_id, :integer
  #   add_index :gantt_issue_settings, [:parent_id]

  #   GanttIssueSetting.find_each do |setting|
  #     issue = Issue.find(setting.issue_id)
  #     setting.update(parent_id: issue.parent_id)
  #   end
  # end
end
