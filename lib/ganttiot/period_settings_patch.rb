module Ganttiot
  module PeriodSettingsPatch
    def self.prepended(base)
      base.prepend(InstanceMethods)
      base.class_eval do
        base.const_get('ALL_PERIODS') << 'decade' << 'half' << 'project'
      end
    end

    module InstanceMethods
      def number_of_periods_by_zoom
        period_end_date = self[:period_end_date]
        period_date_difference = period_end_date ? (period_end_date - self.start_date) + 1 : nil
        case self.zoom.to_s
        when 'decade'
          period_date_difference ? (period_date_difference / 10.0).ceil : 10
        when 'half'
          if period_date_difference
            ((period_end_date.month - start_date.month + 1 + (period_end_date.year - start_date.year) * 12) / 6.0).ceil
          else
            4
          end
        when 'project'
          1
        else
          super
        end
      end

      def zoom_shift(period_count)
        case self.zoom.to_s
        when 'decade'
          (period_count * 10).days
        when 'half'
          (period_count * 6).months
        when 'project'
          period_count.year
        else
          super
        end
      end
    end
  end
end

EasyExtensions::EasyQueryHelpers::PeriodSetting.prepend(Ganttiot::PeriodSettingsPatch)
