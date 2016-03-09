# == Schema Information
#
# Table name: expenses
#
#  id              :integer          not null, primary key
#  expense_type_id :integer
#  claim_id        :integer
#  location        :string
#  quantity        :float
#  rate            :decimal(, )
#  amount          :decimal(, )
#  created_at      :datetime
#  updated_at      :datetime
#  uuid            :uuid
#  reason_id       :integer
#  reason_text     :string
#

require 'rails_helper'

RSpec.describe Expense, type: :model do

  it { should belong_to(:expense_type) }
  it { should belong_to(:claim) }
  it { should have_many(:dates_attended) }

  it { should validate_presence_of(:claim).with_message('blank') }

  context 'expense_reasons and expense reason text' do
    let(:ex_1) { build :expense, reason_id: 1 }
    let(:ex_nil) { build :expense, reason_id: nil }
    let(:ex_5) { build :expense, reason_id: 5, reason_text: 'My unique reason' }

    describe '#expense reason' do
      it 'returns the reason object with id 1' do
        expect(ex_1.expense_reason).to be_instance_of(ExpenseReason)
        expect(ex_1.expense_reason.id).to eq 1
      end

      it 'returns nil if reason_id not set' do
        expect(ex_nil.expense_reason).to be_nil
      end
    end

    describe '#allow_reason_text' do
      it 'returns false if no reason id' do
        expect(ex_nil.allow_reason_text?).to be false
      end
      it 'returns false for reason id 1' do
        expect(ex_1.allow_reason_text?).to be false
      end
      it 'returns true for reason id 5' do
        expect(ex_5.allow_reason_text?).to be true
      end
    end

    describe '#reason_text' do
      it 'returns nil if reason id is nil' do
        expect(ex_nil.reason_text).to be_nil
      end

      it 'returns reason from reason text' do
        expect(ex_1.reason_text).to eq 'Court hearing'
      end

      it 'returns the reason_text from the record for reason id 5' do
        expect(ex_5.reason_text).to eq "My unique reason"
      end
    end
  end

  describe 'set and update amount' do
    subject { build(:expense, rate: 2.5, quantity: 3, amount: 0) }

    context 'for a new expense' do
      it 'sets the expense amount equal to rate x quantity' do
        subject.save!
        expect(subject.amount).to eq(7.5)
      end
    end

    context 'for an existing' do
      before do
        subject.save!
        subject.rate = 3;
        subject.save!
      end

      it 'updates the amount to be equal to the new rate x quantity' do
        expect(subject.amount).to eq(9.0)
      end
    end
  end

  describe 'comma formatted inputs' do
    [:rate, :quantity, :amount].each do |attribute|
      it "converts input for #{attribute} by stripping commas out" do
        expense = build(:expense)
        expense.send("#{attribute}=", '12,321,111')
        expect(expense.send(attribute)).to eq(12321111)
      end
    end
  end

  describe '#quantity' do
    it 'is rounded to the nearest quarter, in a before save hook, if a float is entered' do
      subject = build(:expense, rate: 10, quantity: 1.1, amount: 0)
      expect(subject.quantity).to eq 1.1
      subject.save!
      expect(subject.quantity).to eq 1.0      
    end
  end

end
