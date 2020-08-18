module Gantt
  class UpdateIssueField
    include Dry::Transaction
    LINKS = %I[status priority author assigned_to tracker project category fixed_version parent activity].freeze
    DATES = %I[due_date start_date].freeze
    EDITABLES = (%I[subject description] + LINKS + DATES).freeze

    step :check
    step :update

    private

    def check(issue_id:, name:, val:)
      return Failure(:invalid_params) unless name && val

      issue = Issue.find_by(id: issue_id)
      return Failure(:issue_not_found) unless issue

      customs = issue
        .project
        .issue_custom_fields
        .select(&:editable?)
        .map { |f| :"cf_#{f.id}" }
      return Failure(:non_editable) unless name.to_sym.in?((EDITABLES + customs))

      Success(issue_id: issue_id, name: name, val: val)
    end

    def update(issue_id:, name:, val:)
      issue = Issue.find(issue_id)
      sym = name
      return update_cf(issue, name, val) if name.to_s.start_with?('cf_')

      sym = format('%<name>s_id', name: name) if name.to_sym.in?(LINKS)
      return Failure(:not_updated) unless issue.update(sym => val)

      Success(issue)
    end

    def id_from_name(name)
      /cf_(?<id>\d+)/.match(name.to_s)&.named_captures&.fetch('id').to_i
    end

    def update_cf(issue, name, val)
      value = issue.custom_values.find_by(custom_field_id: id_from_name(name))
      value ||= issue.custom_values.create(custom_field_id: id_from_name(name))
      value.update(value: val.to_s)
      Success(issue)
    end
  end
end
