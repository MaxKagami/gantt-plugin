module Gantt
  class IssueStatusIntervalStruct < BaseStruct
    property :start, transform_with: ->(val) { val.to_time rescue Time.parse(val) rescue nil }
    property :stop, transform_with: ->(val) { val.to_time rescue Time.parse(val) rescue nil }
    property :status_id, transform_with: ->(val) { val.to_i }
    property :issue_id, transform_with: ->(val) { val.to_i }

    def to_width
      w = start && stop ? stop.to_i - start.to_i : nil
      hsh = { width: w, start: start.to_i }
      st = IssueStatus.find(status_id)
      k = :work
      k = :new if status_id == 1
      k = :closed if st.is_closed?
      hsh.merge(kind: k)
    end
  end
end
