module Gantt
  class WorkItemStruct < BaseStruct
    ZOOMS = {
      'week' => 1_100,
      'decade' => 1_540,
      'month' => 4_400,
      'quarter' => 13_200,
      'half' => 26_400,
      'year' => 52_800,
      'project' => 158_400
    }.freeze

    MINS = {
      week: 'day',
      decade: 'day',
      month: 'week',
      quarter: 'month',
      half: 'month',
      year: 'month',
      project: 'quarter'
    }.freeze

    property :kind
    property :width
    property :start

    def z_width(zoom = 'month')
      z = ZOOMS[zoom.to_s].to_f
      ((width || 0) / z).to_i
    end

    def z_start(starting, zoom = 'month')
      z = ZOOMS[zoom.to_s].to_f
      ((start - starting.to_time.to_i) / z).to_i
    end
  end
end
