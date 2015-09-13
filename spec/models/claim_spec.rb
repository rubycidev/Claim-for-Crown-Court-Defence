#
# == Schema Information
#
# Table name: claims
#
#  id                     :integer          not null, primary key
#  additional_information :text
#  apply_vat              :boolean
#  state                  :string(255)
#  submitted_at           :datetime
#  case_number            :string(255)
#  advocate_category      :string(255)
#  indictment_number      :string(255)
#  first_day_of_trial     :date
#  estimated_trial_length :integer          default(0)
#  actual_trial_length    :integer          default(0)
#  fees_total             :decimal(, )      default(0.0)
#  expenses_total         :decimal(, )      default(0.0)
#  total                  :decimal(, )      default(0.0)
#  advocate_id            :integer
#  court_id               :integer
#  offence_id             :integer
#  scheme_id              :integer
#  created_at             :datetime
#  updated_at             :datetime
#  valid_until            :datetime
#  cms_number             :string(255)
#  paid_at                :datetime
#  creator_id             :integer
#  evidence_notes         :text
#  evidence_checklist_ids :string(255)
#  trial_concluded_at     :date
#  trial_fixed_notice_at  :date
#  trial_fixed_at         :date
#  trial_cracked_at       :date
#  trial_cracked_at_third :string(255)
#  source                 :string(255)
#  vat_amount             :decimal(, )      default(0.0)
#  uuid                   :uuid
#  case_type_id           :integer
#

require 'rails_helper'

RSpec.describe Claim, type: :model do

  it { should belong_to(:advocate) }
  it { should belong_to(:creator).class_name('Advocate').with_foreign_key('creator_id') }
  it { should delegate_method(:chamber_id).to(:advocate) }

  it { should belong_to(:court) }
  it { should belong_to(:offence) }
  it { should belong_to(:scheme) }
  it { should have_many(:fees) }
  it { should have_many(:fee_types) }
  it { should have_many(:expenses) }
  it { should have_many(:defendants) }
  it { should have_many(:documents) }
  it { should have_many(:messages) }
  it { should have_many(:case_worker_claims) }
  it { should have_many(:case_workers) }
  it { should have_many(:claim_state_transitions) }

  context 'State Machine meta states magic methods' do
    let(:claim)       { FactoryGirl.build :claim }
    let(:all_states)  { [  'allocated', 'archived_pending_delete', 'awaiting_further_info', 'awaiting_info_from_court',
                           'deleted', 'draft', 'paid', 'part_paid', 'refused', 'rejected', 'submitted' ] }

    context 'advocate_dashboard_draft?' do
      before(:each)     { allow(claim).to receive(:state).and_return('draft') }

      it 'should respond true in draft' do
        allow(claim).to receive(:state).and_return('draft')
        expect(claim.advocate_dashboard_draft?).to be true
      end

      it 'should respond false to anything else' do
        (all_states - ['draft']).each do |state|
          allow(claim).to receive(:state).and_return(state)
          expect(claim.advocate_dashboard_draft?).to be false
        end
      end
    end

    context 'advocate_dashboard_rejected?' do
      before(:each)     { allow(claim).to receive(:state).and_return('rejected') }
      it 'should respond true' do
        allow(claim).to receive(:state).and_return('rejected')
        expect(claim.advocate_dashboard_rejected?).to be true
      end

      it 'should respond false to anything else' do
        (all_states - ['rejected']).each do |state|
          allow(claim).to receive(:state).and_return(state)
          expect(claim.advocate_dashboard_rejected?).to be false
        end
      end
    end

    context 'advocate_dashboard_submitted?' do
      it 'should respond true' do
        [ 'allocated', 'submitted', 'awaiting_info_from_court', 'awaiting_further_info' ].each do |claim_state|
          allow(claim).to receive(:state).and_return(claim_state)
          expect(claim.advocate_dashboard_submitted?).to be true
        end
      end

      it 'should respond false to anything else' do
        (all_states - [ 'allocated', 'submitted', 'awaiting_info_from_court', 'awaiting_further_info' ]).each do |claim_state|
          allow(claim).to receive(:state).and_return(claim_state)
          expect(claim.advocate_dashboard_submitted?).to be false
        end
      end
    end

    context 'advocate_dashboard_part_paid' do
      it 'should respond true' do
        [ 'part_paid' ].each do |state|
          allow(claim).to receive(:state).and_return(state)
          expect(claim.advocate_dashboard_part_paid?).to be true
        end
      end

      it 'should respond false to anything else' do
        (all_states - [ 'part_paid' ]).each do |claim_state|
          allow(claim).to receive(:state).and_return(claim_state)
          expect(claim.advocate_dashboard_part_paid?).to be false
        end
      end
    end

    context 'advocate_dashboard_completed_states' do
      it 'should respond true' do
        [ 'refused', 'paid' ].each do |state|
          allow(claim).to receive(:state).and_return(state)
          expect(claim.advocate_dashboard_completed?).to be true
        end
      end

      it 'should respond false to anything else' do
        (all_states - [ 'refused', 'paid' ]).each do |claim_state|
          allow(claim).to receive(:state).and_return(claim_state)
          expect(claim.advocate_dashboard_completed?).to be false
        end
      end
    end

    context 'unrecognised state' do
      it 'should raise NoMethodError' do
        expect {
          claim.other_unknown_state?
        }.to raise_error NoMethodError, /undefined method `other_unknown_state\?'/
      end
    end
  end

  it { should accept_nested_attributes_for(:basic_fees) }
  it { should accept_nested_attributes_for(:fixed_fees) }
  it { should accept_nested_attributes_for(:misc_fees) }
  it { should accept_nested_attributes_for(:expenses) }
  it { should accept_nested_attributes_for(:defendants) }

  subject { create(:claim) }

  describe '.earliest_representation_order' do
    let(:claim)         { FactoryGirl.build :unpersisted_claim }
    let(:early_date)    { 2.years.ago.to_date }

    before(:each) do
      # add a second defendant
      claim.defendants << FactoryGirl.build(:defendant, claim: claim)

      # add a second rep order to the first defendant
      claim.defendants.first.representation_orders << FactoryGirl.build(:representation_order, representation_order_date: early_date)
    end

    it 'should pick the earliest reporder' do
      # given a claim with two defendants and three rep orders
      expect(claim.defendants).to have_exactly(2).items
      expect(claim.representation_orders).to have_exactly(3).items

      # when I get the earliest rep order
      rep_order = claim.earliest_representation_order

      # it should have a date of
      expect(rep_order.representation_order_date).to eq early_date
    end
  end

  describe '.is_allocated_to_case_worker' do
    let(:case_worker_1)        { FactoryGirl.create :case_worker }
    let(:case_worker_2)        { FactoryGirl.create :case_worker }

    it 'should return true if allocated to the specified case_worker' do
      subject.case_workers << case_worker_1
      subject.case_workers << case_worker_2
      expect(subject.is_allocated_to_case_worker?(case_worker_1)).to be true
    end

    it 'should return false if not allocated to the specified case_worker' do
      subject.case_workers << case_worker_1
      expect(subject.is_allocated_to_case_worker?(case_worker_2)).to be false
    end
  end

  describe '.update_model_and_transition_state' do
    it 'should update the model then transition state to prevent state transition validation errors' do
      # given
      claim = FactoryGirl.create :allocated_claim
      claim.assessment = Assessment.new
      claim_params = {
        "state_for_form"=>"part_paid",
        "assessment_attributes" => {
          "id" => claim.assessment.id,
          "fees" => "66.22",
          "expenses" => "22.33"
        },
        "additional_information"=>""}

      # when
      claim.update_model_and_transition_state(claim_params)
      #then
      expect(claim.reload.state).to eq 'part_paid'
    end

    it 'should not transition when "state_for_form" is the same as the claim\'s state' do
      claim = FactoryGirl.create :paid_claim
      claim_params = {"state_for_form"=>"paid", 'assessment_attributes' => { "fees"=>"88.55", 'expenses' => '0.00'},"additional_information"=>""}
      claim.update_model_and_transition_state(claim_params)
      expect(claim.reload.state).to eq('paid')
    end

    it 'should not transition when "state_for_form" is blank' do
      claim = FactoryGirl.create :paid_claim

      claim_params = {"state_for_form"=>"", 'assessment_attributes' => { "fees"=>"44.55", 'expenses' => '44.00'}, "additional_information"=>""}
      claim.update_model_and_transition_state(claim_params)
      expect(claim.reload.state).to eq('paid')
    end
  end

  context 'basic fees' do
    before(:each) do
      @bft1 = FactoryGirl.create :fee_type, :basic,  description: 'ZZZZ', id: 1
      @mft1 = FactoryGirl.create :fee_type, :misc,   description: 'CCCC', id: 2
      @fft1 = FactoryGirl.create :fee_type, :fixed,  description: 'DDDD', id: 3
      @bft2 = FactoryGirl.create :fee_type, :basic,  description: 'AAAA', id: 4
      @mft2 = FactoryGirl.create :fee_type, :misc,   description: 'EEEE', id: 5
      @bft3 = FactoryGirl.create :fee_type, :basic,  description: 'BBBB', id: 6
    end

    describe '.instantiate_basic_fees' do
      it 'should create a fee record for every basic fee type' do
        # Given three basic fee types and some other non-basic fee types
        # when I instantiate a new claim
        claim = FactoryGirl.build :claim
        claim.instantiate_basic_fees

        # it should also instantiate an emtpy fee for every basic fee type and not for the  other fee types
        expect(claim.fees.size).to eq 3
        claim.fees.each do |fee|
          expect(fee.fee_type.fee_category.abbreviation).to eq 'BASIC'
        end

        # and all fees should be blank
        claim.fees.each { |fee| expect(fee).to be_blank }
      end
    end

    describe '.basic_fees' do
      it 'should return a fee for every basic fee sorted in order of fee type id (i.e. seeded data order)' do
        # Given three basic fee types and some other non-basic fee types and a claim
        claim = FactoryGirl.build :claim
        claim.instantiate_basic_fees

        # when I call basic_fees
        fees = claim.basic_fees

        # it should return the three basic fees sorted in order of fee type id
        expect(fees.map(&:fee_type_id)).to eq( [1, 4, 6])
      end
    end
  end

  describe '.search' do
    let!(:other_claim) { create(:claim) }

    it 'finds only claims with states that match dashboard displayable states' do
      sql = Claim.search(:advocate_name, :defendant_name, :maat_reference, :case_worker_name_or_email, '%').to_sql
      state_in_list_clause = Claims::StateMachine.dashboard_displayable_states.map{ |s| "\'#{s}\'"}.join(', ')
      expect(sql.downcase).to include('where "claims"."state" in (' << state_in_list_clause << ')')
    end

    context 'find by MAAT reference' do
      before do
        create :defendant, claim: subject, representation_orders: [ FactoryGirl.create(:representation_order, maat_reference: '111111') ]
        create :defendant, claim: subject, representation_orders: [ FactoryGirl.create(:representation_order, maat_reference: '222222') ]
        create :defendant, claim: other_claim, representation_orders: [ FactoryGirl.create(:representation_order, maat_reference: '333333') ]
        subject.reload
        other_claim.reload
      end

      it 'finds the claim by MAAT reference "111111"' do
        expect(Claim.search(:maat_reference, '111111')).to eq([subject])
      end

      it 'finds the claim by MAAT reference "222222"' do
        expect(Claim.search(:maat_reference, '222222')).to eq([subject])
      end

      it 'finds the claim by MAAT reference "333333"' do
        expect(Claim.search(:maat_reference, '333333')).to eq([other_claim])
      end

      it 'does not find a claim with MAAT reference "444444"' do
        expect(Claim.search(:maat_reference, '444444')).to be_empty
      end
    end

    context 'find by Defendant name' do
      let!(:current_advocate) { create(:advocate) }
      let!(:other_advocate) { create(:advocate, chamber: current_advocate.chamber ) }

      before do
        subject.advocate = current_advocate
        other_claim.advocate = other_advocate
        subject.save!
        other_claim.save!
        create(:defendant, first_name: 'Joe', middle_name: 'Herbie', last_name: 'Bloggs', claim: subject)
        create(:defendant, first_name: 'Joe', middle_name: 'Herbie', last_name: 'Bloggs', claim: other_claim)
        create(:defendant, first_name: 'Herbie', last_name: 'Hart', claim: other_claim)
        subject.reload
        other_claim.reload
      end

      it 'finds all claims involving specified defendant' do
        expect(Claim.search(:defendant_name, 'Joe Bloggs').count).to eq(2)
      end

      it 'finds claim involving other specified defendant' do
        expect(Claim.search(:defendant_name, 'Hart')).to eq([other_claim])
      end

      it 'does not find claims involving non-existent defendant"' do
        expect(Claim.search(:defendant_name, 'Foo Bar')).to be_empty
      end
    end

    context 'find by Advocate name' do
      before do
        subject.advocate = create(:advocate)
        other_claim.advocate = create(:advocate)
        subject.advocate.user.first_name = 'John'
        subject.advocate.user.last_name = 'Smith'
        subject.advocate.user.save!

        subject.save!

        other_claim.advocate.user.first_name = 'Bob'
        other_claim.advocate.user.last_name = 'Hoskins'
        other_claim.advocate.user.save!

        other_claim.save!
      end

      it 'finds the claim by advocate name "John Smith"' do
        expect(Claim.search(:advocate_name, 'John Smith')).to eq([subject])
      end

      it 'finds the claim by advocate name "Bob Hoskins"' do
        expect(Claim.search(:advocate_name, 'Bob Hoskins')).to eq([other_claim])
      end

      it 'does not find a claim with advocate name "Foo Bar"' do
        expect(Claim.search(:advocate_name, 'Foo Bar')).to be_empty
      end
    end

    context 'find by advocate and defendant' do
      let!(:current_advocate) { create(:advocate) }
      let!(:other_advocate) { create(:advocate, chamber: current_advocate.chamber ) }

      before do

        subject.advocate = current_advocate
        subject.advocate.user.first_name = 'Fred'
        subject.advocate.user.last_name = 'Bloggs'
        subject.advocate.user.save!
        create(:defendant, first_name: 'Joexx', last_name: 'Bloggs', claim: subject)
        subject.save!

        other_claim.advocate = other_advocate
        other_claim.advocate.user.first_name = 'John'
        other_claim.advocate.user.last_name = 'Hoskins'
        other_claim.advocate.user.save!
        create(:defendant, first_name: 'Fred', last_name: 'Hoskins', claim: other_claim)
        other_claim.save!

      end

      it 'finds claims with either advocate or defendant matching names' do
        expect(Claim.search(:advocate_name, :defendant_name, 'Bloggs')).to eq([subject])
        expect(Claim.search(:advocate_name, :defendant_name, 'Hoskins')).to eq([other_claim])
        expect(Claim.search(:advocate_name, :defendant_name, 'Fred').count).to eq(2) #advocate and defendant of name
        expect(Claim.search(:advocate_name, :defendant_name, 'John').count).to eq(1) #advocate only search
        expect(Claim.search(:advocate_name, :defendant_name, 'Joexx').count).to eq(1) #defendant only search
      end

      it 'does not find claims that do not match the name' do
        expect(Claim.search(:advocate_name, :defendant_name, 'Xavierxxxx').count).to eq(0)
      end

    end

    context 'find by case worker name or email' do
      let!(:case_worker) { create(:case_worker) }
      let!(:other_case_worker) { create(:case_worker) }

      before do
        subject.case_workers << case_worker
        other_claim.case_workers << other_case_worker
      end

      it 'finds the claim by case_worker name' do
        expect(Claim.search(:case_worker_name_or_email, case_worker.name)).to eq([subject])
      end

      it 'finds the other claim by case worker name' do
        expect(Claim.search(:case_worker_name_or_email, other_case_worker.name)).to eq([other_claim])
      end

      it 'does not find a claim with a non existent case worker' do
        expect(Claim.search(:case_worker_name_or_email, 'Foo Bar')).to be_empty
      end
    end

    context 'find by invalid option' do
      it 'raises error for invalid option' do
        expect{
          Claim.search(:case_worker_name_or_email, :foo, 'foo')
        }.to raise_error
      end
    end
  end

  context 'fees total' do
    let(:basic_fee) { create(:fee_type, :basic) }
    let(:fixed_fee) { create(:fee_type, :fixed) }
    let(:misc_fee)  { create(:fee_type, :misc)  }

    before do
      create(:fee, fee_type: basic_fee, claim_id: subject.id, amount: 4.00)
      create(:fee, fee_type: basic_fee, claim_id: subject.id, amount: 3.00)
      create(:fee, fee_type: fixed_fee, claim_id: subject.id, amount: 0.50)
      create(:fee, fee_type: misc_fee,  claim_id: subject.id, amount: 0.50)
      subject.reload
    end

    describe '#calculate_fees_total' do
      it 'calculates the fees total' do
        expect(subject.calculate_fees_total).to eq(8.0)
      end

      it 'calculates fee totals by category too' do
        expect(subject.calculate_fees_total(:basic)).to eq(7.0)
        expect(subject.calculate_fees_total(:misc)).to eq(0.5)
        expect(subject.calculate_fees_total(:fixed)).to eq(0.5)
      end
    end

    describe '#update_fees_total' do
      it 'stores the fees total' do
        expect(subject.fees_total).to eq(8.0)
      end

      it 'updates the fees total' do
        create(:fee, fee_type: basic_fee, claim_id: subject.id, amount: 2.00)
        subject.reload
        expect(subject.fees_total).to eq(10.0)
      end

      it 'updates total when claim fee destroyed' do
        fee = subject.fees.first
        fee.destroy
        subject.reload
        expect(subject.fees_total).to eq(4.0)
      end
    end
  end

  context 'expenses total' do
    before do
      create(:expense, claim_id: subject.id, rate: 3.5, quantity: 1)
      create(:expense, claim_id: subject.id, rate: 1.0, quantity: 1)
      create(:expense, claim_id: subject.id, rate: 142.0, quantity: 1)
      subject.reload
    end

    describe '#calculate_expenses_total' do
      it 'calculates expenses total' do
        expect(subject.calculate_expenses_total).to eq(146.5)
      end
    end

    describe '#update_expenses_total' do
      it 'stores the expenses total' do
        expect(subject.expenses_total).to eq(146.5)
      end

      it 'updates the expenses total' do
        create(:expense, claim_id: subject.id, rate: 3.0, quantity: 1)
        subject.reload
        expect(subject.expenses_total).to eq(149.5)
      end

      it 'updates expenses total when expense destroyed' do
        expense = subject.expenses.first
        expense.destroy
        subject.reload
        expect(subject.expenses_total).to eq(143.0)
      end
    end
  end

  context 'total' do
    let(:fee_type) { create(:fee_type) }

    before do
      create(:fee, fee_type: fee_type, claim_id: subject.id, amount: 3.00)
      create(:fee, fee_type: fee_type, claim_id: subject.id, amount: 2.00)
      create(:fee, fee_type: fee_type, claim_id: subject.id, amount: 1.00)

      create(:expense, claim_id: subject.id, rate: 3.5, quantity: 1)
      create(:expense, claim_id: subject.id, rate: 1.0, quantity: 1)
      create(:expense, claim_id: subject.id, rate: 142.0, quantity: 1)
      subject.reload
    end

    describe '#calculate_total' do
      it 'calculates the fees and expenses total' do
        expect(subject.calculate_total).to eq(152.5)
      end
    end

    describe '#update_total' do
      it 'updates the total' do
        create(:expense, claim_id: subject.id, rate: 3.0, quantity: 1)
        create(:fee, fee_type: fee_type, claim_id: subject.id, amount: 0.5)
        subject.reload
        expect(subject.total).to eq(156.00)
      end

      it 'updates total when expense/fee destroyed' do
        expense = subject.expenses.first
        fee = subject.fees.first
        expense.destroy
        fee.destroy
        subject.reload
        expect(subject.total).to eq(146.00)
      end
    end
  end

  describe '#editable?' do
    let(:draft) { create(:claim) }
    let(:submitted) { create(:submitted_claim) }
    let(:allocated) { create(:allocated_claim) }

    it 'should be editable when draft' do
      expect(draft.editable?).to eq(true)
    end

    it 'should be editable when submitted' do
      expect(submitted.editable?).to eq(true)
    end

    it 'should not be editable when allocated' do
      expect(allocated.editable?).to eq(false)
    end
  end

  describe '#transition_state' do
    it 'should call pay! if paid' do
      expect(subject).to receive(:pay!)
      subject.transition_state('paid')
    end
    it 'should call pay_part! if part_paid' do
      expect(subject).to receive(:pay_part!)
      subject.transition_state('part_paid')
    end
    it 'should call reject! if rejected' do
      expect(subject).to receive(:reject!)
      subject.transition_state('rejected')
    end
    it 'should call refuse! if refused' do
      expect(subject).to receive(:refuse!)
      subject.transition_state('refused')
    end
    it 'should call redetermine! if redetermination' do
      expect(subject).to receive(:redetermine!)
      subject.transition_state('redetermination')
    end
    it 'should call await_info_from_court! if awaiting_info_from_court' do
      expect(subject).to receive(:await_info_from_court!)
      subject.transition_state('awaiting_info_from_court')
    end
    it 'should raise an exception if anything else' do
      expect{
        subject.transition_state('allocated')
      }.to raise_error ArgumentError, 'Only the following state transitions are allowed from form input: allocated to paid, part_paid, rejected, refused or awaiting_info_from_court and paid, part_paid or refused to redetermination'
    end
  end

  describe 'STATES_FOR_FORM' do
    it "should have constant values" do
      expect(Claim::STATES_FOR_FORM).to eql({part_paid: "Part paid",
                                            paid: "Paid in full",
                                            rejected: "Rejected",
                                            refused: "Refused",
                                            awaiting_info_from_court: "Awaiting info from court"
                                           })
    end
  end

  describe 'allocate claim when assigning to case worker' do
    subject { create(:submitted_claim) }
    let(:case_worker) { create(:case_worker) }

    it 'moves to "allocated" state when assigned to case worker' do
      subject.case_workers << case_worker
      expect(subject.reload).to be_allocated
    end
  end

  describe 'moves to "submitted" state when case worker removed' do
    subject { create(:submitted_claim) }
    let(:case_worker) { create(:case_worker) }
    let(:other_case_worker) { create(:case_worker) }

    before do
      case_worker.claims << subject
      other_case_worker.claims << subject
      subject.reload
    end

    it 'should be "allocated"' do
      expect(subject).to be_allocated
    end

    context 'when case worker unassigned and other case workers remain' do
      it 'should be "allocated"' do
        case_worker.claims.destroy(subject)
        expect(subject.reload).to be_allocated
      end
    end

    context 'when all case workers unassigned' do
      it 'should be "submitted"' do
        case_worker.claims.destroy(subject)
        other_case_worker.claims.destroy(subject)
        expect(subject.reload).to be_submitted
      end
    end
  end

  describe '#has_paid_state?' do
    let(:claim) { create(:draft_claim) }

    def expect_has_paid_state_to_be(bool)
     expect(claim.has_paid_state?).to eql(bool)
    end

    it 'should return false for draft, submitted, allocated, "awaiting info from court" and rejected claims' do
     expect_has_paid_state_to_be false
     claim.submit
     expect_has_paid_state_to_be false
     claim.allocate
     expect_has_paid_state_to_be false
     claim.await_info_from_court
     expect_has_paid_state_to_be false
     claim.reject
     expect_has_paid_state_to_be false
    end

    it 'should return true for part_paid, paid claims' do
     claim.submit
     claim.allocate
     claim.assessment.update(fees: 30.01, expenses: 70.00)
     claim.pay_part
     expect_has_paid_state_to_be true
     claim.pay
     expect_has_paid_state_to_be true
    end
  end

  describe 'Case type scopes' do
    let!(:case_types)       { load("#{Rails.root}/db/seeds/case_types.rb") }

    let!(:trials)           { create_list(:submitted_claim, 2, case_type: CaseType.by_type('Trial')) }
    let!(:retrials)         { create_list(:submitted_claim, 2, case_type: CaseType.by_type('Retrial')) }
    let!(:cracked_trials)   { create_list(:submitted_claim, 2, case_type: CaseType.by_type('Cracked Trial')) }
    let!(:cracked_retrials) { create_list(:submitted_claim, 2, case_type: CaseType.by_type('Cracked before retrial')) }
    let!(:guilty_pleas)     { create_list(:submitted_claim, 2, case_type: CaseType.by_type('Guilty plea')) }

    describe '.trial' do
      it 'returns trials and retrials' do
        expect(Claim.trial).to match_array(trials + retrials)
      end
    end

    describe '.cracked' do
      it 'returns cracked trials and retrials' do
        expect(Claim.cracked).to match_array(cracked_trials + cracked_retrials)
      end
    end

    describe '.guilty_plea' do
      it 'returns guilty pleas' do
        expect(Claim.guilty_plea).to match_array(guilty_pleas)
      end
    end
  end

  describe '#fixed_fees' do
    let(:ct_fixed_1)          { FactoryGirl.create :case_type, :fixed_fee }
    let(:ct_fixed_2)          { FactoryGirl.create :case_type, :fixed_fee }
    let(:ct_basic_1)          { FactoryGirl.create :case_type }
    let(:ct_basic_2)          { FactoryGirl.create :case_type }

    it 'should only return claims with fixed fee case types' do
      claim_1 = FactoryGirl.create :claim, case_type_id: ct_fixed_1.id
      claim_2 = FactoryGirl.create :claim, case_type_id: ct_fixed_2.id
      claim_3 = FactoryGirl.create :claim, case_type_id: ct_basic_1.id
      claim_4 = FactoryGirl.create :claim, case_type_id: ct_basic_2.id

      expect(Claim.fixed_fee).to eq( [ claim_1, claim_2 ])
    end
  end


  describe '.total_greater_than_or_equal_to' do
    let(:not_greater_than_400) do
      claims = []

      [100, 200, 399, 2].each do |value|
        claims << create(:submitted_claim, total: value)
      end

      claims
    end

    let(:greater_than_400) do
      claims = []

      [400, 10_000, 566, 1_000].each do |value|
        claims << create(:submitted_claim, total: value)
      end

      claims
    end

    it 'only returns claims with total value greater than the specified value' do
      expect(Claim.total_greater_than_or_equal_to(400)).to match_array(greater_than_400)
    end
  end

  describe '.destroy_all_invalid_fee_types' do

    let(:claim_with_all_fee_types) do
      claim = FactoryGirl.create :draft_claim
      FactoryGirl.create(:fee, :basic, claim: claim, amount: 9.99)
      FactoryGirl.create(:fee, :fixed, claim: claim, amount: 9.99)
      FactoryGirl.create(:fee, :misc, claim: claim, amount: 9.99)
      claim
    end

    it 'destroys fixed fees for non fixed case types' do
      claim_with_all_fee_types.save
      expect(claim_with_all_fee_types.basic_fees.map(&:amount).sum.to_f).to eql 9.99
      expect(claim_with_all_fee_types.fixed_fees.size).to eql 0
      expect(claim_with_all_fee_types.misc_fees.size).to eql 1
    end

    it 'clears basic fees and destroys miscelllaneous fees for Fixed Fee case types' do
      claim_with_all_fee_types.case_type = CaseType.find_or_create_by!(name: 'Fixed fee', is_fixed_fee: true)
      claim_with_all_fee_types.save
      expect(claim_with_all_fee_types.basic_fees.map(&:amount).sum.to_f).to eql 0.0
      expect(claim_with_all_fee_types.fixed_fees.size).to eql 1
      expect(claim_with_all_fee_types.misc_fees.size).to eql 0
    end

  end

  describe 'sets the source field before saving a claim' do
    let(:claim)       { FactoryGirl.build :claim }

    it 'sets the source to web by default if unset' do
      expect(claim.save).to eq(true)
      expect(claim.source).to eq('web')
    end

    it 'does not change the source if set' do
      claim.source = 'api'
      expect(claim.save).to eq(true)
      expect(claim.source).to eq('api')
    end

  end


  describe 'calculate_vat' do

    it 'should calaculate vat before saving if vat is applied' do
      allow(VatRate).to receive(:vat_amount).and_return(99.44)
      claim = FactoryGirl.build :unpersisted_claim, fees_total: 1500.22, expenses_total: 500.00, apply_vat: true, submitted_at: Date.today
      claim.save!
      expect(claim.vat_amount).to eq 99.44
    end

    it 'should zeroise the vat amount if vat is not applied' do
      claim = FactoryGirl.build :unpersisted_claim, fees_total: 1500.22, expenses_total: 500.00, apply_vat: false, vat_amount: 88.22, submitted_at: Date.today
      claim.save!
      expect(claim.vat_amount).to eq 0.0
    end

    it 'should zeroise the vat amount if submitted at date is blank' do
      claim = FactoryGirl.build :unpersisted_claim, fees_total: 1500.22, expenses_total: 500.00, apply_vat: false, vat_amount: 88.22
      claim.save!
      expect(claim.vat_amount).to eq 0.0
    end
  end

  describe '#opened_for_redetermination?' do
    let(:claim) { create(:claim) }

    before do
      claim.submit!
      claim.allocate!
      claim.refuse!
    end

    context 'when transitioned to redetermination' do
      before do
        claim.redetermine!
      end

      it 'should be in an redetermination state' do
        expect(claim).to be_redetermination
      end

      it 'should be open for redetermination' do
        expect(claim.opened_for_redetermination?).to eq(true)
      end
    end

    context 'when transitioned to allocated' do
      before do
        claim.redetermine!
        claim.allocate!
      end

      it 'should be in an allocated state' do
        expect(claim).to be_allocated
      end

      it 'should have been opened for redetermination before being allocated' do
        expect(claim.opened_for_redetermination?).to eq(true)
      end
    end
  end

  describe 'comma formatted inputs' do
    [:fees_total, :expenses_total, :total, :vat_amount].each do |attribute|
      it "converts input for #{attribute} by stripping commas out" do
        claim = build(:claim)
        claim.send("#{attribute}=", '12,321,111')
        expect(claim.send(attribute)).to eq(12321111)
      end
    end
  end

  describe '#written_reasons_outstanding?' do
    let(:claim) { create(:claim) }

    before do
      claim.submit!
      claim.allocate!
      claim.refuse!
    end

    context 'when transitioned to awaiting_written_reasons' do
      before do
        claim.await_written_reasons!
      end

      it 'should be in an awaiting_written_reasons state' do
        expect(claim).to be_awaiting_written_reasons
      end

      it 'should be awaiting_written_reasons' do
        expect(claim.written_reasons_outstanding?).to eq(true)
      end
    end

    context 'when transitioned to allocated' do
      before do
        claim.await_written_reasons!
        claim.allocate!
      end

      it 'should be in an allocated state' do
        expect(claim).to be_allocated
      end

      it 'should have written_reasons_outstanding before being allocated' do
        expect(claim.written_reasons_outstanding?).to eq(true)
      end
    end
  end

  describe '#requested_redetermination?' do

    context 'allocated state from redetermination' do

      before(:each) do
        @claim = FactoryGirl.create :redetermination_claim
        @claim.allocate!
      end

      context 'no previous redetermination' do

        it 'should be true' do
          expect(@claim.redeterminations).to be_empty
          expect(@claim.requested_redetermination?).to be true
        end
      end

      context 'previous redetermination record created before state was changed to redetermination' do
        it 'should be true' do
          Timecop.freeze(Time.now - 2.hours) do
            @claim.redeterminations << Redetermination.new(fees: 12.12, expenses: 35.55)
            Timecop.freeze(Time.now ) do
              @claim.pay_part!
              @claim.redetermine!
              @claim.allocate!
            end
            expect(@claim.requested_redetermination?).to be true
          end
        end
      end


      context 'latest redetermination created after transition to redetermination' do
        it 'should be false' do
          Timecop.freeze(Time.now + 10.minutes) do
            @claim.redeterminations << Redetermination.new(fees: 12.12, expenses: 35.55)
          end
          expect(@claim.requested_redetermination?).to be false
        end
      end

    end

    context 'allocated state where the previous state was not redetermination' do
      it 'should be false' do
        claim = FactoryGirl.create :allocated_claim
        expect(claim.requested_redetermination?).to be false
      end
    end

    context 'not allocated state' do
      it 'should be false' do
        claim = FactoryGirl.create :redetermination_claim
        expect(claim.requested_redetermination?).to be false
      end
    end

  end

  describe 'not saving the expenses model' do
    it 'should save the expenses model' do
      advocate = FactoryGirl.create :advocate
      expense_type = FactoryGirl.create :expense_type
      fee_scheme = FactoryGirl.create :scheme
      fee_type = FactoryGirl.create :fee_type
      case_type = FactoryGirl.create :case_type
      court = FactoryGirl.create :court
      offence = FactoryGirl.create :offence



      params = {"claim"=>
        {"case_type_id"=>case_type.id,
         "trial_fixed_notice_at_dd"=>"",
         "trial_fixed_notice_at_mm"=>"",
         "trial_fixed_notice_at_yyyy"=>"",
         "trial_fixed_at_dd"=>"",
         "trial_fixed_at_mm"=>"",
         "trial_fixed_at_yyyy"=>"",
         "trial_cracked_at_dd"=>"",
         "trial_cracked_at_mm"=>"",
         "trial_cracked_at_yyyy"=>"",
         "trial_cracked_at_third"=>"",
         "court_id"=>court.id,
         "case_number"=>"A12345678",
         "advocate_category"=>"QC",
         "advocate_id" => advocate.id,
         "offence_id"=>offence.id,
         "first_day_of_trial_dd"=>"8",
         "first_day_of_trial_mm"=>"9",
         "first_day_of_trial_yyyy"=>"2015",
         "estimated_trial_length"=>"0",
         "actual_trial_length"=>"0",
         "trial_concluded_at_dd"=>"11",
         "trial_concluded_at_mm"=>"9",
         "trial_concluded_at_yyyy"=>"2015",
         "defendants_attributes"=>
          {"0"=>
            {"first_name"=>"Foo",
             "middle_name"=>"",
             "last_name"=>"Bar",
             "date_of_birth_dd"=>"04",
             "date_of_birth_mm"=>"10",
             "date_of_birth_yyyy"=>"1980",
             "order_for_judicial_apportionment"=>"0",
             "representation_orders_attributes"=>
              {"0"=>
                {"granting_body"=>"Crown Court",
                 "representation_order_date_dd"=>"30",
                 "representation_order_date_mm"=>"08",
                 "representation_order_date_yyyy"=>"2015",
                 "maat_reference"=>"aaa1111",
                 "_destroy"=>"false"}},
             "_destroy"=>"false"}},
         "additional_information"=>"",
         "basic_fees_attributes"=>
          {"0"=>{"quantity"=>"1", "amount"=>"0.5", "fee_type_id"=>fee_type.id}},
         "misc_fees_attributes"=>{"0"=>{"fee_type_id"=> "", "quantity"=>"", "amount"=>"", "_destroy"=>"false"}},
         "fixed_fees_attributes"=>{"0"=>{"fee_type_id"=>"", "quantity"=>"", "amount"=>"", "_destroy"=>"false"}},
         "expenses_attributes"=>{"0"=>{"expense_type_id"=>expense_type.id, "location"=>"London", "quantity"=>"1", "rate"=>"40", "_destroy"=>"false"}},
         "apply_vat"=>"0",
         "document_ids"=>[""],
         "evidence_checklist_ids"=>["1", ""]},
       "offence_category"=>{"description"=>""},
       "offence_class"=>{"description"=>"64"},
       "commit"=>"Submit to LAA"}
      claim = Claim.new(params['claim'])
      claim.creator = advocate
      claim.force_validation = true
      expect(claim.save).to be true
      expect(claim.expenses).to have(1).member
      expect(claim.expenses_total).to eq 40.0
      

    end
  end
end
