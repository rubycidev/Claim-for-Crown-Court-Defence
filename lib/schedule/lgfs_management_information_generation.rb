module Schedule
  class LGFSManagementInformationGeneration
    include Sidekiq::Job

    def perform
      LogStuff.info { 'LGFS Management Information Generation started' }
      Stats::StatsReportGenerator.call(report_type: 'lgfs_management_information')
      LogStuff.info { 'LGFS Management Information Generation finished' }
    rescue StandardError => e
      LogStuff.error { 'LGFS Management Information Generation error: ' + e.message }
    end
  end
end
