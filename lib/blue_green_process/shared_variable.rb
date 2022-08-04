# frozen_string_literal: true

require 'singleton'

module BlueGreenProcess
  class SharedVariable
    include Singleton

    attr_accessor :data

    def restore(json)
      self.data = json.slice(*BlueGreenProcess.config.shared_variables)
    end

    def dump
      data.slice(*BlueGreenProcess.config.shared_variables)
    end
  end
end
