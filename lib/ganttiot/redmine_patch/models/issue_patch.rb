module GanttiotPlugin
  module IssuePatch
    def self.included(base)
      base.prepend(InstanceMethods)
      base.class_eval do
        has_one :easy_baseline_sources,
                -> { where(relation_type: 'Issue') },
                class_name: 'EasyBaselineSource',
                foreign_key: :destination_id,
                dependent: :nullify
        has_many :easy_baseline_destinations,
                 -> { where(relation_type: 'Issue') },
                 class_name: 'EasyBaselineSource',
                 foreign_key: :source_id,
                 dependent: :destroy

        after_save :create_baseline_from_copy, if: :copy?
      end
    end

    module InstanceMethods
      def total_spent_estimated_timeentries
        super
      end

      def create_baseline_from_copy
        return if project.easy_baseline_for_id.nil?

        EasyBaselineSource.create(
          baseline_id: project_id,
          relation_type: 'Issue',
          source_id: @copied_from.id,
          destination_id: id
        )
      end

      def issue_diff_end
        ((Gantt::CalcIssueTimingsQuery.new(issue: self).issue_diff_end || 0) / 86_400.0).round
      end

      def issue_diff_start
        ((Gantt::CalcIssueTimingsQuery.new(issue: self).issue_diff_start || 0) / 86_400.0).round
      end

      def issue_diff_duration
        ((Gantt::CalcIssueTimingsQuery.new(issue: self).issue_diff_duration || 0) / 86_400.0).round
      end
    end
  end
end
RedmineExtensions::PatchManager.register_model_patch 'Issue', 'GanttiotPlugin::IssuePatch'
