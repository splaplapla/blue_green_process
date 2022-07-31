# frozen_string_literal: true

module BlueGreenProcess
  class Config
    def after_fork=(block)
      @after_fork_block = block
    end

    def after_fork
      @after_fork_block || -> {}
    end
  end
end
