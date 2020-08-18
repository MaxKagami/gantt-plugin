module GanttiotPlugin
  module ProjectPatch
    def self.included(base)
      base.singleton_class.prepend(ClassMethods)
      base.prepend(InstanceMethods)

      base.class_eval do
        belongs_to :easy_baseline_for, class_name: 'Project'
        has_many :easy_baseline_sources, foreign_key: 'baseline_id', dependent: :destroy
        has_many :easy_baselines, class_name: 'Project', foreign_key: 'easy_baseline_for_id', dependent: :destroy

        before_save :prevent_unarchive_easy_baseline

        scope :no_baselines, (proc { where(easy_baseline_for_id: nil).where.not(identifier: EasyBaseline::IDENTIFIER) })
      end
    end

    module ClassMethods
      def allowed_to_condition(user, permission, options = {}, &block)
        return super unless options[:easy_baseline].present?

        super.gsub!("#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND", '')
      end

      def next_identifier
        p = Project
          .where.not(identifier: EasyBaseline::IDENTIFIER)
          .where(easy_baseline_for_id: nil)
          .order('id DESC')
          .first
        p.nil? ? nil : p.identifier.to_s.succ
      end
    end

    module InstanceMethods
      def baseline_root?
        identifier == Gantt::Baseline::IDENTIFIER
      end

      def copy_versions(project)
        super
        return unless easy_baseline_for_id == project.id

        versions.each do |v|
          v.copied_from = project.versions.detect { |cv| cv.name == v.name }
          v.save
        end
      end

      def allows_to_with_easy_baseline?(action)
        return true if easy_baseline_for_id && archived?

        super
      end

      def validate_custom_field_values
        return true if baseline_root? && archived?

        super
      end

      private

      def validate_parent
        return errors.add(:parent_id, :invalid) if @unallowed_parent_id

        return unless parent_id_changed?

        return unless unallowed_move_to_parent?

        errors.add(:parent_id, :invalid)
      end

      def unallowed_move_to_parent?
        parent.present? && (!parent.active? || !move_possible?(parent)) && !parent.baseline_root?
      end

      def prevent_unarchive_easy_baseline
        return unless (easy_baseline_for_id || baseline_root?) && status_changed? && !archived?

        errors.add(:status, :invalid)
        false
      end
    end
  end
end
RedmineExtensions::PatchManager.register_model_patch 'Project', 'GanttiotPlugin::ProjectPatch'
