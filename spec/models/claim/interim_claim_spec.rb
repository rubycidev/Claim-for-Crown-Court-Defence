# == Schema Information
#
# Table name: claims
#
#  id                       :integer          not null, primary key
#  additional_information   :text
#  apply_vat                :boolean
#  state                    :string
#  last_submitted_at        :datetime
#  case_number              :string
#  advocate_category        :string
#  first_day_of_trial       :date
#  estimated_trial_length   :integer          default(0)
#  actual_trial_length      :integer          default(0)
#  fees_total               :decimal(, )      default(0.0)
#  expenses_total           :decimal(, )      default(0.0)
#  total                    :decimal(, )      default(0.0)
#  external_user_id         :integer
#  court_id                 :integer
#  offence_id               :integer
#  created_at               :datetime
#  updated_at               :datetime
#  valid_until              :datetime
#  cms_number               :string
#  authorised_at            :datetime
#  creator_id               :integer
#  evidence_notes           :text
#  evidence_checklist_ids   :string
#  trial_concluded_at       :date
#  trial_fixed_notice_at    :date
#  trial_fixed_at           :date
#  trial_cracked_at         :date
#  trial_cracked_at_third   :string
#  source                   :string
#  vat_amount               :decimal(, )      default(0.0)
#  uuid                     :uuid
#  case_type_id             :integer
#  form_id                  :string
#  original_submission_date :datetime
#  retrial_started_at       :date
#  retrial_estimated_length :integer          default(0)
#  retrial_actual_length    :integer          default(0)
#  retrial_concluded_at     :date
#  type                     :string
#  disbursements_total      :decimal(, )      default(0.0)
#  case_concluded_at        :date
#  transfer_court_id        :integer
#  supplier_number          :string
#  effective_pcmh_date      :date
#  legal_aid_transfer_date  :date
#  allocation_type          :string
#  transfer_case_number     :string
#  clone_source_id          :integer
#  last_edited_at           :datetime
#  deleted_at               :datetime
#  providers_ref            :string
#

require 'rails_helper'
require 'custom_matchers'
require_relative 'shared_examples_for_lgfs_claim'

RSpec.describe Claim::InterimClaim, type: :model do

  let(:claim) { build :interim_claim }

  it { should delegate_method(:requires_trial_dates?).to(:case_type) }
  it { should delegate_method(:requires_retrial_dates?).to(:case_type) }

  describe '#interim?' do
    it 'should return true' do
      expect(claim.interim?).to eql true
    end
  end

  describe '#eligible_case_types' do
    it 'should return only Interim case types' do
      CaseType.delete_all

      create :case_type, name: 'AGFS case type', roles: ['agfs']
      create :case_type, name: 'LGFS case type', roles: ['lgfs']
      ct1 = create :case_type, name: 'LGFS and Interim case type', roles: %w(lgfs interim)
      ct2 = create :case_type, name: 'AGFS, LGFS and Interim case type', roles: %w(agfs lgfs interim)

      expect(claim.eligible_case_types.sort).to eq([ct1, ct2].sort)
    end
  end

  include_examples "common litigator claim attributes"

end
