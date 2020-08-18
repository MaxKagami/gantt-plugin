class GanttIssueForm < BaseForm
  property :author_id
  property :assigned_to_id
  property :subject
  property :description
  property :project_id
  property :tracker_id
  property :parent_id
  # property :user, type: User
  # property :amount, type: Float
  # property :date_from, type: Date
  # property :date_to, type: Date
  # property :data, writeable: false, populator: :data_populate!
  # property :projects, writeable: false, populator: :projects_populate!
  # property :report, writeable: false, populator: :report_populate!

  validation :default, with: { form: true } do
    required(:author_id).filled
    required(:assigned_to_id).filled
    required(:subject).filled
    required(:project_id).filled
    required(:tracker_id).filled
  end
end
