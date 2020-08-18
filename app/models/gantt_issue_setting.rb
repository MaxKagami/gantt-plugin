class GanttIssueSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  unloadable

  serialize :column_settings, JSON

  safe_attributes :column_names, :column_settings, :query_params

  belongs_to :project
  belongs_to :issue
  belongs_to :principal, foreign_key: :user_id

  acts_as_list scope: %i[project_id user_id parent_id]

  after_initialize :init
  before_save :cvt_settings

  def get_params
    JSON.parse(query_params) rescue {}
  end

  def get_names
    YAML.load(column_names) rescue []
  end

  private

  def init
    self.column_settings ||= {}
  end

  def cvt_settings
    if column_settings.is_a? Array
      tmp = column_settings.each_with_object({}) { |hsh, obj| obj[hsh['kind']] = hsh['width'] }
      self.column_settings = tmp
    end
    true
  end
end
