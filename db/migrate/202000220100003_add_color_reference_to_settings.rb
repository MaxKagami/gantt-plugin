class AddColorReferenceToSettings < ActiveRecord::Migration[5.2]
  def change
    add_reference :gantt_issue_settings, :current_color, references: :color
  end
end