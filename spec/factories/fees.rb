# == Schema Information
#
# Table name: fees
#
#  id          :integer          not null, primary key
#  claim_id    :integer
#  fee_type_id :integer
#  quantity    :integer
#  amount      :decimal(, )
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryGirl.define do
  factory :fee do
    claim
    fee_type
    quantity 1
    amount "9.99"

    trait :random_values do
      quantity { rand(1..15) }
      amount   { rand(100.00..9999.99).round(2) }
    end

    trait :basic do
      fee_type { FactoryGirl.create :fee_type, :basic }
    end

    trait :misc do
      fee_type { FactoryGirl.create :fee_type, :misc }
    end

    trait :fixed do
      fee_type { FactoryGirl.create :fee_type, :fixed }
    end

    trait :all_zero do
      quantity 0
      amount 0
    end

  end

end
