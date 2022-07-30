# frozen_string_literal: true
require 'blue_green_proces/master_process'
require 'blue_green_proces/child_process'
require 'blue_green_proces/base_worker'

require_relative "blue_green_process/version"

module BlueGreenProcess
  class Error < StandardError; end

  PROCESS_STATUS_ACTIVE = :active
  PROCESS_STATUS_INACTIVE = :inactive

  PROCESS_COMMAND_DIE  = 'die'
  PROCESS_COMMAND_BE_ACTIVE = 'be_active'
  PROCESS_COMMAND_BE_INACTIVE = 'work'
  PROCESS_COMMAND_WORK = 'be_inactive'

  PROCESS_RESPONSE = 'ACK'

  def self.fork_process(label: , worker_class: )
    child_read, parent_write = IO.pipe
    parent_read, child_write = IO.pipe
    worker_instance = worker_class.new

    pid = fork do
      parent_write.close
      parent_read.close
      process_status = :inactive

      loop do
        data = child_read.gets&.strip
        case data
        when PROCESS_COMMAND_DIE, nil, ''
          debug_log "#{label}'ll die(#{$$})"
          break
        when PROCESS_COMMAND_BE_ACTIVE
          process_status = PROCESS_STATUS_ACTIVE
          debug_log "#{label}'ll be active(#{$$})"
          child_write.puts PROCESS_RESPONSE
          ::GC.disable
        when PROCESS_COMMAND_BE_INACTIVE
          process_status = PROCESS_STATUS_INACTIVE
          debug_log "#{label}'ll be inactive(#{$$})"
          child_write.puts PROCESS_RESPONSE
          ::GC.enable
          ::GC.start
        when PROCESS_COMMAND_WORK
          warn 'Should not be able to run in this status' if process_status == PROCESS_STATUS_INACTIVE

          debug_log "#{label}'ll work(#{$$})"
          worker_instance.work
          child_write.puts PROCESS_RESPONSE
        else
          child_write.puts "NG"
          debug_log "unknown. from #{label}(#{$$})"
        end
      end
    end

    child_write.close
    child_read.close

    ChildProcess.new(pid, label, parent_read, parent_write)
  end

  def self.new(worker_class: , max_work: )
    BlueOrGreenProcess::MasterProcess.new((worker_class: worker_class, max_work: max_work)
  end

  def self.debug_log(message)
    return unless ENV['VERBOSE']
    puts message
  end
end
