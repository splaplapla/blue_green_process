# frozen_string_literal: true

module BlueGreenProcess
  class WorkerProcess
    attr_accessor :pid, :label, :rpipe, :wpipe, :status

    def initialize(pid, label, rpipe, wpipe)
      self.pid = pid
      self.label = label
      self.rpipe = rpipe
      self.wpipe = wpipe
      self.status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
    end

    def be_active
      return self if status == BlueGreenProcess::PROCESS_STATUS_ACTIVE

      write_and_await_until_read(BlueGreenProcess::PROCESS_COMMAND_BE_ACTIVE,
                                 { data: BlueGreenProcess::SharedVariable.instance.data })
      self.status = BlueGreenProcess::PROCESS_STATUS_ACTIVE
      self
    end

    def be_inactive
      return self if status == BlueGreenProcess::PROCESS_STATUS_INACTIVE

      write_and_await_until_read(BlueGreenProcess::PROCESS_COMMAND_BE_INACTIVE)
      self.status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
      self
    end

    def work
      enforce_to_be_active

      write_and_await_until_read(BlueGreenProcess::PROCESS_COMMAND_WORK)
    end

    def shutdown
      write(BlueGreenProcess::PROCESS_COMMAND_DIE)
    end

    private

    def write_and_await_until_read(command, args = {})
      write(command, args)
      wait_response
    end

    def wait_response
      response = JSON.parse(read)
      BlueGreenProcess::SharedVariable.instance.restore(response["data"])
      case response["c"]
      when BlueGreenProcess::RESPONSE_OK
        return [BlueGreenProcess::SharedVariable.instance.data, response]
      when BlueGreenProcess::RESPONSE_ERROR
        raise BlueGreenProcess::ErrorWrapper.new(response["err_class"], response["err_message"])
      else
        raise "invalid response."
      end
    end

    def read
      rpipe.gets.strip
    end

    def write(token, args = {})
      wpipe.puts({ c: token }.merge!(args).to_json)
    end

    def enforce_to_be_active
      raise "activeじゃないのにrunできないです" if status != BlueGreenProcess::PROCESS_STATUS_ACTIVE
    end
  end
end
