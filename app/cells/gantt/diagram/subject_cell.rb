module Gantt::Diagram
  class SubjectCell < Cell::ViewModel
    include ::Rails.application.routes.url_helpers

    self.view_paths = ['plugins/ganttiot/app/cells']

    # model: issue

    def show
      render
    end

    def numbers
      nums = options.fetch(:pref, []) + [options.fetch(:order, 1)]
      "<div class='numbers'>#{nums.map(&:to_s).join('.')}.</div>"
    end
  end
end
