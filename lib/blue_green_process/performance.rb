# frozen_string_literal: true

module BlueGreenProcess
  class Performance
    attr_accessor  :process_switching_time_before_work

    def process_switching_time_before_work
      @process_switching_time_before_work || 0
    end
  end
end
