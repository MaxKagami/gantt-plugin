module Gantt
  class TreeNode < BaseStruct
    property :issues
    property :project
    property :issue
    property :children
    property :baselines
    property :source
    property :position
    # property :user, transform_with: ->(val) { User.find_by(id: val) }

    def working
      return [] unless issue && issues.present?

      [[Time.zone.new(2019, 1, 5), [Time.zone.new(2019, 2, 3)]]]
    end

    def calculated
      return [] unless issue && baselines.present?

      [[Time.zone.new(2019, 1, 5), [Time.zone.new(2019, 1, 31)]]]
    end

    def id
      (issue || project)&.id
    end

    def char
      (issue || project).class.name.first.downcase
    end
  end
end
