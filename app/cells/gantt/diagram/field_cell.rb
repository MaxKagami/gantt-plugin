module Gantt::Diagram
  class FieldCell < Cell::ViewModel
    include ::Rails.application.routes.url_helpers

    self.view_paths = ['plugins/ganttiot/app/cells']

    property :attributes

    def show
      render
    end

    def edit
      render(:edit)
    end

    def internal
      render(:internal)
    end

    def values(field)
      return [] unless field

      case field.to_sym
      when :status
        model.new_statuses_allowed_to(User.current).map { |stat| [stat.id, stat.name] }
      when :author
        model.project.members.map { |m| [m.user_id, m.user.name] }
      when :assigned_to
        model.project.members.map { |m| [m.user_id, m.user.name] }
      when :project
        ['', ''] + Project.active.allowed_to(User.current).pluck(:id, :name)
      when :tracker
        model.project.trackers.pluck(:id, :name)
      when :priority
        IssuePriority.all.pluck(:id, :name)
      else
        []
      end
    end

    def datatype(field)
      return 'string' unless field

      return 'string' if field == 'subject'

      return 'text' if field == 'description'

      return 'list' if field.to_sym.in?(Gantt::UpdateIssueField::LINKS)

      return cf_type(field) if field.start_with?('cf_')

      return 'date' if model.respond_to?(field.to_sym) &&
                       (
                         model.send(field.to_sym)&.is_a?(Date) ||
                         field.to_sym.in?(%i[start_date due_date])
                       )

      'string'
    end

    def hide?
      set = GanttIssueSetting.find_by(issue_id: model.id, user_id: User.current.id)
      set&.hide_children?
    end

    def editable?(fieldname, _issue = nil)
      return true if fieldname == 'spent_estimated_timeentries' && model.children.blank?

      fieldname.to_sym.in?(Gantt::UpdateIssueField::EDITABLES) ||
        (fieldname =~ /cf_\d+/ && cf(fieldname)&.editable?)
    end

    def cf(name)
      id = /cf_(?<id>\d+)/.match(name.to_s)&.named_captures&.fetch('id')
      return nil unless id

      IssueCustomField.find(id)
    end

    def cf_type(field)
      _tp = %w[user string list text amount attachment date link int country_select float bool easy_percent]
      f = cf(field)
      f&.field_format.yield_self { |s| s || 'string' }
    end

    def value(field)
      return '' unless field

      return model.subject if field == 'subject'

      return model.send(field.to_sym)&.name if field.in?(%w[author assigned_to status tracker project priority])

      return calc_val(field) if field.start_with?('cf_')

      attributes[field]
    end

    def calc_val(fieldname)
      id = /cf_(?<id>\d+)/.match(fieldname.to_s)&.named_captures&.fetch('id')
      model.custom_values.find_by(custom_field_id: id.to_i)&.value || ''
    end
  end
end
