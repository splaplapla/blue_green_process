# frozen_string_literal: true

require "logger"

module BlueGreenProcess
  class Config
    attr_writer :logger, :shared_variables

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
    end

    def shared_variables=(value)
      @shared_variables = value.map(&:to_s)
    end
  end
end
