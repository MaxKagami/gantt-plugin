module Gantt
  class NewIssueStruct < BaseStruct
    property :assigned_to_id
    property :subject
    property :description
    property :tracker_id
    property :project_id
    property :author_id
    property :parent_id

    def save
      Issue.create({ status_id: 1 }.merge(self))
    end
  end
end
