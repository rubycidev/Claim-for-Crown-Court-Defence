# == Schema Information
#
# Table name: disbursement_types
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

RSpec.describe DisbursementType, type: :model do

  it { should have_many(:disbursements) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }

  context 'scopes' do

    before(:all) do
      create :disbursement_type, name: 'Zebras'
      create :disbursement_type, name: 'Travel Costs', deleted_at: 3.minutes.ago
      create :disbursement_type, name: 'Aardvarks'
    end

    after(:all) { DisbursementType.delete_all }

    describe 'default scope' do
      it 'returns in alphabetical order by name' do
        expect(DisbursementType.all.map(&:name)).to eq([ 'Aardvarks', 'Travel Costs', 'Zebras' ])
      end
    end

    describe 'active scope' do
      it 'excludes records with non-nil deleted_at' do
        expect(DisbursementType.active.map(&:name)).to eq([ 'Aardvarks', 'Zebras' ])
      end
    end
  end
end
