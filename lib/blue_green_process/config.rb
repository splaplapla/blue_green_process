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
  end
end
