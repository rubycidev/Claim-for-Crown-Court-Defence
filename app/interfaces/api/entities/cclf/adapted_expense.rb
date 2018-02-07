module API
  module Entities
    module CCLF
      class AdaptedExpense < AdaptedBaseBill
        with_options(format_with: :string) do
          expose :amount, as: :net_amount
          expose :vat_amount
        end

        private

        delegate :bill_type, :bill_subtype, to: :adapter

        def adapter
          @adapter ||= ::CCLF::ExpenseAdapter.new(object)
        end
      end
    end
  end
end
