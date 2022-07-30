# frozen_string_literal: true

module BlueGreenProcess
  class ChildProcess
    attr_accessor :pid, :label, :rpipe, :wpipe, :status

    def initialize(pid, label, rpipe, wpipe)
      self.pid = pid
      self.label = label
      self.rpipe = rpipe
      self.wpipe = wpipe
      self.status = PROCESS_STATUS_INACTIVE
    end

    def be_active
      return self if status == PROCESS_STATUS_ACTIVE

      write_and_await_until_read(PROCESS_COMMAND_BE_ACTIVE)
      self.status = PROCESS_STATUS_ACTIVE
      self
    end

    def be_inactive
      return self if status == PROCESS_STATUS_INACTIVE

      write_and_await_until_read(PROCESS_COMMAND_BE_INACTIVE)
      self.status = PROCESS_STATUS_INACTIVE
      self
    end

    def work
      enforce_to_be_active

      write_and_await_until_read(PROCESS_COMMAND_WORK)
    end

    private

    def write_and_await_until_read(command)
      write(command)
      wait_response
    end

    def wait_response
      response = read
      raise "invalid response." unless response == PROCESS_RESPONSE
    end

    def read
      rpipe.gets.strip
    end

    def write(token)
      wpipe.puts token
    end

    def enforce_to_be_active
      raise "activeじゃないのにrunできないです" if status != PROCESS_STATUS_ACTIVE
    end
  end
end
