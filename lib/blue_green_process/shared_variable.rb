# frozen_string_literal: true

require "singleton"

module BlueGreenProcess
  class SharedVariable
    include Singleton

    attr_writer :data

    def self.data
      instance.data
    end

    def self.data=(value)
      instance.data = value
    end

    def self.extend_run_on_this_process
      instance.extend_run_on_this_process
    end

    def self.extend_run_on_this_process=(value)
      instance.extend_run_on_this_process = (value)
    end

    # @return [Hash]
    def data
      @data ||= {}
    end

    # @return [Boolean]
    def extend_run_on_this_process
      @data["extend_run_on_this_process"] ||= false
    end

    # @return [Boolean]
    def extend_run_on_this_process=(value)
      @data["extend_run_on_this_process"] = value
    end

    # @return [Hash]
    def restore(json)
      return if json.nil?

      self.data = json.slice(*BlueGreenProcess.config.shared_variables)
    end

    # @return [Hash]
    def dump
      data.slice(*BlueGreenProcess.config.shared_variables)
    end

    # @return [NilClass]
    def reset
      @data = nil
    end
  end
end
