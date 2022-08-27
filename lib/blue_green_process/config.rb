# frozen_string_literal: true

require "logger"

module BlueGreenProcess
  class Config
    attr_writer :logger

    def after_fork=(block)
      @after_fork_block = block
    end

    def after_fork
      @after_fork_block || -> {}
    end

    def logger
      @logger ||= Logger.new("/dev/null")
    end

    def shared_variables
      @shared_variables ||= []
      @shared_variables.push(:extend_run_on_this_process)
      @shared_variables.uniq
    end

    def shared_variables=(value)
      @shared_variables = value.map(&:to_s)
      @shared_variables.push("extend_run_on_this_process")
      @shared_variables.uniq
    end
  end
end
