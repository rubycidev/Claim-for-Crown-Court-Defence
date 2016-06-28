require 'rails_helper'


module Stats

  describe ClaimSubmissionsDataGenerator do
    it 'should instantiate' do
      populate_statistics_table
      expect(ClaimSubmissionsDataGenerator.new.run).to eq expected_output
    end

    def populate_statistics_table
      advocates = [250, 260, 270, 280, 290]
      interims = [150, 160, 170, 180, 190]
      litigators = [350, 360, 370, 380, 390]
      transfers = [50, 60, 70 ,80, 90]

      populate_statistics_records('Advocate', advocates)
      populate_statistics_records('Interim', interims)
      populate_statistics_records('Litigator', litigators)
      populate_statistics_records('Transfer', transfers)
    end

    def populate_statistics_records(abbreviated_claim_type, dataset)
      date = Date.yesterday - dataset.size.days
      claim_type = "Claim::#{abbreviated_claim_type}Claim"
      dataset.each do |data_value|
        Statistic.create(report_name: 'claim_submissions', claim_type: claim_type, date: date, value_1: data_value)
        date += 1.day
      end
    end

    def expected_output
      {
        'series' => [
          {
            'name' => 'Advocate claims',
            'data' => [250, 260, 270, 280, 290],
          },
          {
            'name' => 'Interim claims',
            'data' => [150, 160, 170, 180, 190],
          },
          {
            'name' => 'Litigator claims',
            'data' => [350, 360, 370, 380, 390],
          },
          {
            'name' => 'Transfer claims',
            'data' => [50, 60, 70 ,80, 90]
          }
        ]
      }.to_json
    end
  end
end


