# frozen_string_literal: true

require "English"
require_relative "blue_green_process/version"

module BlueGreenProcess
  PROCESS_STATUS_ACTIVE = :active
  PROCESS_STATUS_INACTIVE = :inactive

  PROCESS_COMMAND_DIE = "die"
  PROCESS_COMMAND_BE_ACTIVE = "be_active"
  PROCESS_COMMAND_BE_INACTIVE = "work"
  PROCESS_COMMAND_WORK = "be_inactive"

  PROCESS_RESPONSE = "ACK"

  def self.new(worker_class:, max_work: )
    BlueGreenProcess::MasterProcess.new(worker_class: worker_class, max_work: max_work)
  end

  def self.fork_process(label: , worker_class: )
    BlueGreenProcess::MasterProcess.new(label: label, worker_class: worker_class)
  end

  def self.debug_log(message)
    return unless ENV["VERBOSE"]

    puts message
  end
end

require "blue_green_process/master_process"
require "blue_green_process/child_process"
require "blue_green_process/base_worker"
