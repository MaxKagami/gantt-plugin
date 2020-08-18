module Gantt
  class IssueWorkingStatus
    def initialize(issue, base = nil)
      @issue = issue
      @base = base
    end

    def calc
      @history = status_changes
      int = late_internal
      ksg = late_ksg
    end

    private

    def status_changes

    end

    def late_internal

    end

    def late_ksg

    end
  end
end
