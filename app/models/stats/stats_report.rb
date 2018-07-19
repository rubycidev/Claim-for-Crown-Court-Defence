# == Schema Information
#
# Table name: stats_reports
#
#  id           :integer          not null, primary key
#  report_name  :string
#  report       :string
#  status       :string
#  started_at   :datetime
#  completed_at :datetime
#

module Stats
  class StatsReport < ApplicationRecord
    TYPES = %w[management_information provisional_assessment].freeze

    validates :status, inclusion: { in: %w[started completed error] }

    default_scope { order('started_at DESC') }

    scope :completed, -> { where(status: 'completed') }
    scope :errored, -> { where(status: 'error') }
    scope :not_errored, -> { where('status != ?', 'error') }

    scope :management_information, -> { not_errored.where(report_name: 'management_information') }
    scope :provisional_assessment, -> { not_errored.where(report_name: 'provisional_assessment') }

    def self.clean_up(report_name)
      destroy_reports_older_than(report_name, 1.month.ago)
      destroy_unfinished_reports_older_than(report_name, 2.hours.ago)
    end

    def self.most_recent_by_type(report_type)
      where(report_name: report_type).completed.first
    end

    def self.most_recent_management_information
      management_information.completed.first
    end

    def self.generation_in_progress?(report_name)
      where('report_name = ? and status = ?', report_name, 'started').any?
    end

    def self.record_start(report_name)
      create!(report_name: report_name, status: 'started', started_at: Time.now)
    end

    def write_report(report_contents)
      update(report: report_contents, status: 'completed', completed_at: Time.now)
    end

    def write_error(report_contents)
      update(report: report_contents, status: 'error', completed_at: nil)
    end

    def download_filename
      "#{report_name}_#{started_at.strftime('%Y_%m_%d_%H_%M_%S')}.csv"
    end

    def self.destroy_reports_older_than(report_name, timestamp)
      where(report_name: report_name, started_at: Time.at(0)..timestamp).destroy_all
    end

    def self.destroy_unfinished_reports_older_than(report_name, timestamp)
      where(report_name: report_name, status: 'started', started_at: Time.at(0)..timestamp).destroy_all
    end
  end
end
