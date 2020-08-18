module Gantt::Baseline
  IDENTIFIER = 'easy_baselines-root'.freeze

  def baseline_root_project
    Project.find_by(identifier: IDENTIFIER)
  end

  module_function :baseline_root_project
end
