module Gantt
  class UpdateQueryParams
    include Dry::Transaction

    step :load_setting
    step :update

    private

    def load_setting(project:, user:, params:)
      setting = GanttIssueSetting.find_by(project_id: project.id, user_id: user.id, issue_id: nil) ||
                GanttIssueSetting.create(project_id: project.id, user_id: user.id, issue_id: nil)
      return Success(setting: setting, params: params) if setting

      Failure(:error_setting_load)
    end

    def update(setting:, params:)
      if params[:clear].present?
        clr = params[:clear]
        query = JSON.parse(setting.query_params || '{}').yield_self { |s| s || {} }
        clr.each { |k| query.delete(k) }
        setting.query_params = JSON.generate(query)
        GanttIssueSetting.where(id: setting.id).update_all(query_params: setting.query_params)
      end
      if params[:params].present?
        query = JSON.parse(setting.query_params || '{}').yield_self { |s| s || {} }.merge(params[:params].permit!)
        query.each { |_k, v| v.delete(v.first) if v == ['---'] }
        setting.query_params = JSON.generate(query)
        GanttIssueSetting.where(id: setting.id).update_all(query_params: setting.query_params)
      end
      if params[:column_names].present?
        names = params[:column_names]
        GanttIssueSetting.where(id: setting.id).update_all(column_names: YAML.dump(names))
      end
      setting = GanttIssueSetting.where(id: setting.id)
      Success(setting)
    end
  end
end
