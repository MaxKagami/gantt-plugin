module GanttiotPlugin
  module VersionPatch
    def self.included(base)
      base.class_eval do
        attr_accessor :copied_from

        after_save :create_baseline_from_copy, if: :copy?

        def copy?
          @copied_from.present?
        end

        private

        def create_baseline_from_copy
          return if project.easy_baseline_for_id.nil?

          EasyBaselineSource.create(
            baseline_id: project_id,
            relation_type: 'Version',
            source_id: @copied_from.id,
            destination_id: id
          )
        end
      end
    end
  end
end
RedmineExtensions::PatchManager.register_model_patch 'Version', 'GanttiotPlugin::VersionPatch'
