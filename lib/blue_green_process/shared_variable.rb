# frozen_string_literal: true

require 'singleton'

module BlueGreenProcess
  class SharedVariable
    include Singleton

    attr_writer :data

    def data
      @data ||= {}
    end

    def restore(json)
      return if json.nil?
      self.data = json.slice(*BlueGreenProcess.config.shared_variables)
    end

    def dump
      data.slice(*BlueGreenProcess.config.shared_variables)
    end

    def reset
      @data = nil
    end
  end
end
