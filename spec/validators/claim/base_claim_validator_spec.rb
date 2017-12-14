require 'rails_helper'
require_relative '../validation_helpers'

describe Claim::BaseClaimValidator do
  include ValidationHelpers

  let(:claim)                       { FactoryBot.create :claim }

  let(:guilty_plea)                 { FactoryBot.build :case_type, :fixed_fee, name: 'Guilty plea'}
  let(:contempt)                    { FactoryBot.build :case_type, :requires_trial_dates, name: 'Contempt' }
  let(:retrial)                     { FactoryBot.build :case_type, :retrial }
  let(:breach_of_crown_court_order) { FactoryBot.build :case_type, name: 'Breach of Crown Court order'}
  let(:cracked_trial)               { FactoryBot.build :case_type, :requires_cracked_dates, name: "Cracked trial" }
  let(:cracked_before_retrial)      { FactoryBot.build :case_type, :requires_cracked_dates, name: 'Cracked before retrial'}

  before do
    claim.force_validation = true
    claim.estimated_trial_length = 1
    claim.actual_trial_length = 2
  end

  it 'test claim should be valid' do
    expect(claim.valid?).to be true
  end

  context 'transition state dependant validation' do
    let(:invalid_claim) do
      nulify_fields_on_record(claim, :court)
      claim.fees.destroy_all
      claim.expenses.destroy_all
      claim
    end

    context 'when claim is in draft state' do
      context 'during submission' do
        before do
          invalid_claim.defendants.first.update_attribute(:first_name, nil)
          invalid_claim.defendants.first.representation_orders.first.update_attribute(:maat_reference, nil)
        end

        it 'validation is performed on claim' do
          expect { invalid_claim.submit! }.to raise_error StateMachines::InvalidTransition, /reason.*court/i
        end

        it 'validation is performed on defendants sub model' do
          expect { invalid_claim.submit! }.to raise_error StateMachines::InvalidTransition, /reason.*defendant.*first name.*/i
        end

        it 'validation is performed on representation_orders sub-sub-model' do
          expect { invalid_claim.submit! }.to raise_error StateMachines::InvalidTransition, /reason.*representation order.*maat reference.*/i
        end
      end

      context 'when saving as draft' do
        context '...and validation is forced' do
          before { invalid_claim.force_validation = true }

          it 'validation is performed' do
            expect(invalid_claim).to_not be_valid
          end
        end

        context '...and validation is NOT forced' do
          before { invalid_claim.force_validation = false }

          context '...and it is coming from the api' do
            before { invalid_claim.source = 'api' }

            it 'validation is performed' do
              expect(invalid_claim).to_not be_valid
            end
          end

          context '...and it is coming from the web app' do
            before { invalid_claim.source = 'web' }

            it 'validation is NOT performed' do
              expect(invalid_claim).to be_valid
            end
          end
        end
      end
    end

    context 'when claim is in archived_pending_delete state' do
      let(:claim) { create(:archived_pending_delete_claim) }

      before do
        nulify_fields_on_record(claim, :case_type, :court, :case_number, :advocate_category, :offence, :estimated_trial_length, :actual_trial_length)
        claim.force_validation = false
      end

      it 'validation is NOT performed' do
        expect(claim).to be_valid
      end
    end

    context 'when claim is in submitted state' do
      before do
        claim.submit!
        claim.force_validation = false
        nulify_fields_on_record(claim, :case_type, :court, :case_number, :advocate_category, :offence, :estimated_trial_length, :actual_trial_length)
        claim.defendants.destroy_all
        claim.fees.destroy_all
        claim.expenses.destroy_all
      end

      it 'validation is performed' do
        expect(claim).to_not be_valid
      end

      context 'during allocation' do
        it 'validation is NOT performed' do
          expect { claim.allocate! }.to_not raise_error
        end
      end

      context 'during authorisation' do
        before { claim.allocate! }

        context 'when assessment included' do
          it 'raises no errors' do
            claim.update_amount_assessed(fees: 100.00)
            expect { claim.authorise! }.to_not raise_only_amount_assessed_error
          end
        end

        context 'when assessment NOT included' do
          it 'raises only amount assessed errors' do
            expect { claim.authorise! }.to raise_only_amount_assessed_error
          end
        end
      end

      context 'during part authorisation' do
        before { claim.allocate! }

        context 'when assessment included' do
          it 'raises no errors' do
            claim.update_amount_assessed(fees: 100.00)
            expect { claim.authorise_part! }.to_not raise_only_amount_assessed_error
          end
        end

        context 'when assessment NOT included' do
          it 'raises only amount assessed errors' do
            expect { claim.authorise_part! }.to raise_only_amount_assessed_error
          end
        end
      end

      context 'during redetermination' do
        before { claim.allocate!; claim.reject! }
        it 'validation is NOT performed' do
          expect { claim.redetermine! }.to_not raise_error
        end
      end

      context 'during awaiting_written_reasons' do
        before { claim.allocate!; claim.reject! }
        it 'validation is NOT performed' do
          expect { claim.await_written_reasons! }.to_not raise_error
        end
      end

      context 'during refusal' do
        before { claim.allocate! }
        it 'validation is NOT performed' do
          expect { claim.refuse! }.to_not raise_error
        end
      end

      context 'during rejection' do
        before { claim.allocate! }
        it 'validation is NOT performed' do
          expect { claim.reject! }.to_not raise_error
        end
      end

      context 'during deallocation' do
        before { claim.allocate! }
        it 'validation is NOT performed' do
          expect { claim.deallocate! }.to_not raise_error
        end
      end
    end
  end

  context 'total' do
    before do
      allow(claim).to receive(:total).and_return(total)
      claim.form_step = 2
    end

    context 'when total is not greater than 0' do
      let(:total) { 0.0 }

      it 'should error' do
        should_error_with(claim, :total, 'numericality')
      end
    end

    context 'when total is greater than the max limit' do
      let(:total) { 1_000_123 }

      it 'should error' do
        should_error_with(claim, :total, 'claim_max_amount')
      end
    end
  end

  context 'case_number' do
    it 'should error if not present' do
      claim.case_number = nil
      should_error_with(claim, :case_number, "blank")
    end

    it 'should not error if valid' do
      claim.case_number = 'T20161234'
      expect(claim).to be_valid
    end

    it 'should error if invalid' do
      claim.case_number = 'T87654321'
      should_error_with(claim, :case_number, 'invalid')
    end

    it 'upcases the first letter and does not error' do
      claim.case_number = 't20161234'
      expect(claim).to be_valid
      expect(claim.case_number).to eq 'T20161234'
    end

    it 'validates against the regex' do
      %w(A S T U).each do |letter|
        (1990..2020).each do |year|
          %w(0001 1111 9999).each do |number|
            case_number = [letter, year, number].join
            expect(case_number.match(BaseValidator::CASE_NUMBER_PATTERN)).to be_truthy
          end
        end
      end
    end
  end

  context 'estimated_trial_length' do
    it 'should error if not present and case type requires trial dates' do
      claim.case_type = contempt
      claim.estimated_trial_length = nil
      should_error_with(claim, :estimated_trial_length, "blank")
    end

    it 'should NOT error if not present and case type does NOT require trial dates' do
      claim.case_type = guilty_plea
      claim.estimated_trial_length = nil
      should_not_error(claim,:estimated_trial_length)
    end

    it 'should error if less than zero' do
      claim.case_type = contempt
      claim.estimated_trial_length = -1
      should_error_with(claim, :estimated_trial_length, "invalid")
    end
  end

  context 'actual_trial_length' do
    it 'should error if not present and case type requires trial dates' do
      claim.case_type = contempt
      claim.actual_trial_length = nil
      should_error_with(claim, :actual_trial_length, "blank")
    end

    it 'should NOT error if not present and case type does NOT require trial dates' do
      claim.case_type = guilty_plea
      claim.actual_trial_length = nil
      should_not_error(claim,:actual_trial_length)
    end

    it 'should error if less than zero' do
      claim.case_type = contempt
      claim.actual_trial_length = -1
      should_error_with(claim, :actual_trial_length, "invalid")
    end
  end

  context 'retrial_estimated_length' do
    it 'should error if not present and case type requires retrial dates' do
      claim.case_type = retrial
      claim.retrial_estimated_length = nil
      should_error_with(claim, :retrial_estimated_length, "blank")
    end

    it 'should NOT error if not present and case type does NOT require retrial dates' do
      claim.case_type = guilty_plea
      claim.retrial_estimated_length = nil
      should_not_error(claim,:retrial_estimated_length)
    end

    it 'should error if less than zero' do
      claim.case_type = retrial
      claim.retrial_estimated_length = -1
      should_error_with(claim, :retrial_estimated_length, "invalid")
    end
  end

  context 'retrial_actual_length' do
    it 'should error if not present and case type requires retrial dates' do
      claim.case_type = retrial
      claim.retrial_actual_length = nil
      should_error_with(claim, :retrial_actual_length, "blank")
    end

    it 'should NOT error if not present and case type does NOT require retrial dates' do
      claim.case_type = guilty_plea
      claim.retrial_actual_length = nil
      should_not_error(claim,:retrial_actual_length)
    end

    it 'should error if less than zero' do
      claim.case_type = retrial
      claim.retrial_actual_length = -1
      should_error_with(claim, :retrial_actual_length, "invalid")
    end
  end

  context 'trial_cracked_at_third' do

    context 'for cracked trials' do
      before { claim.case_type = cracked_trial }

      it 'should error if NOT present' do
        claim.trial_cracked_at_third = nil
        should_error_with(claim,:trial_cracked_at_third,"blank")
      end

      it 'should error if NOT in expected value list' do
        # NOTE: stored value is snake case
        claim.trial_cracked_at_third ='Final third'
        should_error_with(claim,:trial_cracked_at_third, "invalid")
      end

      Settings.trial_cracked_at_third.each do |third|
        it "can be \"#{third}\" third for Cracked trials" do
            claim.trial_cracked_at_third = third
            claim.valid?
            expect(claim.errors[:trial_cracked_at_third]).to be_empty
        end
      end
    end

    context 'for cracked before retrial' do
      before { claim.case_type = cracked_before_retrial }

      it 'should error if NOT present' do
        claim.trial_cracked_at_third = nil
        should_error_with(claim,:trial_cracked_at_third,"blank")
      end

      it 'should error if NOT in expected value list' do
        # NOTE: stored value is snake case
        claim.trial_cracked_at_third ='Final third'
        should_error_with(claim,:trial_cracked_at_third, "invalid")
      end

      it 'should error if NOT final third' do
        claim.trial_cracked_at_third ='first_third'
        should_error_with(claim,:trial_cracked_at_third,"invalid_case_type_third_combination")
      end
    end

    context 'for other case types' do
      before { claim.case_type = guilty_plea}
      it 'should not error if not present' do
        claim.trial_cracked_at_third = nil
        should_not_error(claim, :trial_cracked_at_third)
      end
    end
  end

  context 'amount_assessed' do
    before { claim.submit!; claim.allocate! }

    let(:assessed_claim)  do
      claim.update_amount_assessed(fees: 101.22, expenses: 28.55, disbursements: 92.66)
      claim
    end

    it 'should NOT error if assessment provided prior to authorise! or part_authorise! transistions' do
      expect{ assessed_claim.authorise! }.to_not raise_error
    end

    it 'should error if NO assessment present and state is transitioned to authorised or part_authorised' do
      expect{ claim.authorise! }.to raise_error(StateMachines::InvalidTransition)
      expect{ claim.authorise_part! }.to raise_error(StateMachines::InvalidTransition)
    end

    it 'should error if authorised claim has assessment zeroized' do
      assessed_claim.authorise!
      assessed_claim.assessment.zeroize!
      expect(assessed_claim).to_not be_valid
      expect(assessed_claim.errors[:amount_assessed]).to eq( ['Amount assessed cannot be zero for claims in state Authorised'] )
    end

    it 'should error if authorised claim has assessment updated to zero' do
      assessed_claim.authorise_part!
      assessed_claim.assessment.update(fees: 0, expenses: 0, disbursements: 0)
      expect(assessed_claim).to_not be_valid
      expect(assessed_claim.errors[:amount_assessed]).to eq( ['Amount assessed cannot be zero for claims in state Part authorised'] )
    end

    context 'should be valid if amount assessed is zero' do
        %w{ draft allocated refused rejected submitted }.each do |state|
          it "for claims in state #{state}" do
            factory_name = "#{state}_claim".to_sym
            claim = FactoryBot.create factory_name
            expect(claim.assessment.total).to eq 0
            expect(claim).to be_valid
          end
        end
    end

    context 'should be invalid if amount assessed is not zero' do
      %w{ draft refused rejected submitted }.each do |state|
        it "should error if amount assessed is not zero for #{state}" do
          factory_name = "#{state}_claim".to_sym
          claim = FactoryBot.create factory_name
          claim.assessment.fees = 35.22
          expect(claim).to_not be_valid
          expect(claim.errors[:amount_assessed]).to eq( ["Amount assessed must be zero for claims in state #{state.humanize}"] )
        end
      end
    end

    context 'when creator has been made invalid' do
      before { assessed_claim.creator = create(:external_user, :litigator) }

      context 'and validation has been overridden' do
        before { assessed_claim.disable_for_state_transition = :all }

        it { expect(assessed_claim.valid?).to be true }
      end

      context 'and validation has been overridden only for amount_assessed' do
        before { assessed_claim.disable_for_state_transition = :only_amount_assessed }

        it { expect(assessed_claim.valid?).to be false }
      end

      context 'and validation has not been overridden' do
        before { assessed_claim.disable_for_state_transition = nil }

        it { expect(assessed_claim.valid?).to be false }
      end
    end
  end

  context 'evidence_checklist_ids' do

    let(:doc_types) { DocType.all.sample(4).map(&:id) }
    let(:invalid_ids) { ['a','ABC','??','-'] }

    it 'should serialize and deserialize as Array' do
      claim.evidence_checklist_ids = doc_types
      should_not_error(claim,:evidence_checklist_ids)
      claim.save!
      dup = Claim::BaseClaim.active.find claim.id
      expect(dup.evidence_checklist_ids).to eq( doc_types )

    end

    it 'should NOT error if ids are string integers and should exclude blank strings' do
      claim.evidence_checklist_ids = ['9','2',' ']
      should_not_error(claim,:evidence_checklist_ids)
    end

    it 'should NOT error if ids are valid doctype ids' do
      claim.evidence_checklist_ids = doc_types
      should_not_error(claim,:evidence_checklist_ids)
    end

    it "should error if ids are zero or strings" do
      invalid_ids.each do |id|
        claim.evidence_checklist_ids = [id]
        should_error_with(claim,:evidence_checklist_ids,"Evidence checklist ids are of an invalid type or zero, please use valid Evidence checklist ids")
      end
    end

    it 'should error if, and for each, id that is not valid doctype ids' do
      claim.evidence_checklist_ids = [101,1001,200,32]
      expect(claim.valid?).to be false
      expect(claim.errors[:evidence_checklist_ids]).to include(/^Evidence checklist id 101 is invalid, please use valid evidence checklist ids/)
    end

    it 'should throw an exception for anything other than an array' do
      expect {
        claim.evidence_checklist_ids = '1, 45, 457'
        claim.save!
      }.to raise_error ActiveRecord::SerializationTypeMismatch, /Attribute was supposed to be a Array, but was a String. -- "1, 45, 457"/i
    end

    context 'when evidence_checklist_ids have been made invalid' do
      before { claim.evidence_checklist_ids = [101,1001,200,32] }

      context 'and validation has been overridden' do
        before { claim.disable_for_state_transition = :all }

        it { expect(claim.valid?).to be true }
      end

      describe 'and validation has been overridden for amount_assessed' do
        context 'using the correct symbol' do
          before { claim.disable_for_state_transition = :only_amount_assessed }

          it { expect(claim.valid?).to be true }
        end

        context 'using the wrong symbol' do
          before { claim.disable_for_state_transition = :leave_amount }

          it { expect(claim.valid?).to be false }
        end
      end

      context 'and validation has not been overridden' do
        before { claim.disable_for_state_transition = nil }

        it { expect(claim.valid?).to be false }
      end
    end
  end

  context 'cracked (re)trials' do
    let(:cracked_trial_claim) do
      claim = FactoryBot.create :claim, case_type: cracked_trial
      nulify_fields_on_record(claim, :trial_fixed_notice_at, :trial_fixed_at, :trial_cracked_at)
    end

    let(:cracked_before_retrial_claim) do
      claim = FactoryBot.create :claim, case_type: cracked_before_retrial
      nulify_fields_on_record(claim, :trial_fixed_notice_at, :trial_fixed_at, :trial_cracked_at)
    end

    before do
      cracked_trial_claim.force_validation = true
      cracked_before_retrial_claim.force_validation = true
    end

    context 'trial_fixed_notice_at' do
      context 'cracked_trial_claim' do
        it { should_error_if_not_present(cracked_trial_claim, :trial_fixed_notice_at, 'blank', translated_message: 'Enter a date') }
        it { should_error_if_in_future(cracked_trial_claim, :trial_fixed_notice_at, 'check_not_in_future', translated_message: 'Can\'t be in the future')}
        it { should_error_if_too_far_in_the_past(cracked_trial_claim, :trial_fixed_notice_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_after_specified_field(cracked_trial_claim, :trial_fixed_notice_at, :trial_fixed_at, 'check_before_trial_fixed_at') }
        it { should_error_if_after_specified_field(cracked_trial_claim, :trial_fixed_notice_at, :trial_cracked_at, 'check_before_trial_cracked_at') }
        it { should_error_if_field_dates_match(cracked_trial_claim, :trial_fixed_notice_at, :trial_cracked_at, 'check_before_trial_cracked_at') }
        it { should_error_if_field_dates_match(cracked_trial_claim, :trial_fixed_notice_at, :trial_fixed_at, 'check_before_trial_fixed_at') }
      end

      context 'cracked_before_retrial claim' do
        it { should_error_if_not_present(cracked_before_retrial_claim, :trial_fixed_notice_at, 'blank') }
        it { should_error_if_in_future(cracked_before_retrial_claim, :trial_fixed_notice_at, 'check_not_in_future', translated_message: 'Can\'t be in the future') }
        it { should_error_if_too_far_in_the_past(cracked_before_retrial_claim, :trial_fixed_notice_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_after_specified_field(cracked_trial_claim, :trial_fixed_notice_at, :trial_fixed_at, 'check_before_trial_fixed_at') }
        it { should_error_if_after_specified_field(cracked_trial_claim, :trial_fixed_notice_at, :trial_cracked_at, 'check_before_trial_cracked_at') }
        it { should_error_if_field_dates_match(cracked_trial_claim, :trial_fixed_notice_at, :trial_cracked_at, 'check_before_trial_cracked_at') }
        it { should_error_if_field_dates_match(cracked_trial_claim, :trial_fixed_notice_at, :trial_fixed_at, 'check_before_trial_fixed_at') }
      end
    end

    context 'trial fixed at' do
      context 'cracked trial claim' do
        it { should_error_if_not_present(cracked_trial_claim, :trial_fixed_at, 'blank', translated_message: 'Enter a date') }
        it { should_error_if_too_far_in_the_past(cracked_trial_claim, :trial_fixed_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_earlier_than_other_date(cracked_trial_claim, :trial_fixed_at, :trial_fixed_notice_at, 'check_not_earlier_than_trial_fixed_notice_at', translated_message: 'Can\'t be before the "Notice of 1st fixed/warned issued"') }
      end

      context 'cracked before retrial' do
        it { should_error_if_not_present(cracked_before_retrial_claim, :trial_fixed_at, 'blank', translated_message: 'Enter a date') }
        it { should_error_if_too_far_in_the_past(cracked_before_retrial_claim, :trial_fixed_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_earlier_than_other_date(cracked_before_retrial_claim, :trial_fixed_at, :trial_fixed_notice_at, 'check_not_earlier_than_trial_fixed_notice_at', translated_message: 'Can\'t be before the "Notice of 1st fixed/warned issued"') }
      end
    end

    context 'trial cracked at' do
      context 'cracked trial' do
        it { should_error_if_not_present(cracked_trial_claim, :trial_cracked_at, 'blank', translated_message: 'Enter a date') }
        it { should_error_if_in_future(cracked_trial_claim, :trial_cracked_at, 'check_not_in_future', translated_message: 'Can\'t be in the future') }
        it { should_error_if_too_far_in_the_past(cracked_trial_claim, :trial_cracked_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_earlier_than_other_date(cracked_trial_claim, :trial_cracked_at, :trial_fixed_notice_at, 'check_not_earlier_than_trial_fixed_notice_at', translated_message: 'Can\'t be before the "Notice of 1st fixed/warned issued"') }
      end

      context 'cracked before retrial' do
        it { should_error_if_not_present(cracked_before_retrial_claim, :trial_cracked_at, 'blank', translated_message: 'Enter a date') }
        it { should_error_if_in_future(cracked_before_retrial_claim, :trial_cracked_at, 'check_not_in_future', translated_message: 'Can\'t be in the future') }
        it { should_error_if_too_far_in_the_past(cracked_before_retrial_claim, :trial_cracked_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
        it { should_error_if_earlier_than_other_date(cracked_before_retrial_claim, :trial_cracked_at, :trial_fixed_notice_at, 'check_not_earlier_than_trial_fixed_notice_at', translated_message: 'Can\'t be before the "Notice of 1st fixed/warned issued"') }
      end
    end
  end

  context 'for claims requiring trial details' do
    context 'first day of trial' do
      let(:contempt_claim_with_nil_first_day) { nulify_fields_on_record(FactoryBot.create(:claim, case_type: contempt), :first_day_of_trial) }
      before { contempt_claim_with_nil_first_day.force_validation = true }
      it { should_error_if_not_present(contempt_claim_with_nil_first_day, :first_day_of_trial, "blank", translated_message: 'Enter a date') }
      it { should_errror_if_later_than_other_date(contempt_claim_with_nil_first_day, :first_day_of_trial, :trial_concluded_at, 'check_other_date', translated_message: 'Can\'t be after the date "Trial concluded"') }
      it { should_error_if_earlier_than_earliest_repo_date(contempt_claim_with_nil_first_day, :first_day_of_trial, 'check_not_earlier_than_rep_order', translated_message: 'Can\'t be before the earliest rep. order') }
      it { should_error_if_too_far_in_the_past(contempt_claim_with_nil_first_day, :first_day_of_trial, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
    end

    context 'trial_concluded_at' do
      let(:contempt_claim_with_nil_concluded_at) { nulify_fields_on_record(FactoryBot.create(:claim, case_type: contempt), :trial_concluded_at) }
      before { contempt_claim_with_nil_concluded_at.force_validation = true }
      it { should_error_if_not_present(contempt_claim_with_nil_concluded_at, :trial_concluded_at, "blank", translated_message: 'Enter a date') }
      it { should_error_if_earlier_than_other_date(contempt_claim_with_nil_concluded_at, :trial_concluded_at, :first_day_of_trial, 'check_other_date', translated_message: 'Can\'t be before the "First day of trial"') }
      it { should_error_if_earlier_than_earliest_repo_date(contempt_claim_with_nil_concluded_at, :trial_concluded_at, 'check_not_earlier_than_rep_order', translated_message: 'Can\'t be before the earliest rep. order') }
      it { should_error_if_too_far_in_the_past(contempt_claim_with_nil_concluded_at, :trial_concluded_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
    end
  end

  context 'for claims requiring retrial details' do
    let(:claim) { FactoryBot.create(:claim, case_type: retrial) }

    context 'retrial_started_at' do
      it { should_error_if_not_present(claim, :retrial_started_at, "blank", translated_message: 'Enter a date') }
      it { should_errror_if_later_than_other_date(claim, :retrial_started_at, :retrial_concluded_at, 'check_other_date', translated_message: 'Can\'t be after the date "Retrial concluded"') }
      it { should_error_if_earlier_than_earliest_repo_date(claim, :retrial_started_at, 'check_not_earlier_than_rep_order', translated_message: 'Can\'t be before the earliest rep. order') }
      it { should_error_if_too_far_in_the_past(claim, :retrial_started_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }

      it 'shoud NOT error if first day of trial is before the claims earliest rep order' do
        stub_earliest_rep_order(claim, 1.month.ago)
        claim.first_day_of_trial = 2.months.ago
        expect(claim.valid?).to be true
        expect(claim.errors[:retrial_started_at]).to be_empty
      end
    end

    context 'retrial_concluded_at' do
      it { should_error_if_not_present(claim, :retrial_concluded_at, "blank", translated_message: 'Enter a date') }
      it { should_error_if_earlier_than_other_date(claim, :retrial_concluded_at, :retrial_started_at, 'check_other_date', translated_message: 'Can\'t be before the "First day of retrial"') }
      it { should_error_if_earlier_than_earliest_repo_date(claim, :retrial_concluded_at, 'check_not_earlier_than_rep_order', translated_message: 'Can\'t be before the earliest rep. order') }
      it { should_error_if_too_far_in_the_past(claim, :retrial_concluded_at, 'check_not_too_far_in_past', translated_message: 'Can\'t be too far in the past') }
      
      it 'shoud NOT error if first day of trial is before the claims earliest rep order' do
        stub_earliest_rep_order(claim, 1.month.ago)
        claim.first_day_of_trial = 2.months.ago
        expect(claim.valid?).to be true
        expect(claim.errors[:retrial_concluded_at]).to be_empty
      end
    end
  end
end
