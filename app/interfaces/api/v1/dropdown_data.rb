module API
  module V1
    class DropdownData < API::Helpers::GrapeApiHelper
      params do
        optional :api_key, type: String, desc: 'REQUIRED: The API authentication key of the provider'
      end

      helpers do
        params :role_filter do
          optional :role, type: String, desc: I18n.t('api.v1.dropdown_data.params.role_filter'), values: %w[agfs lgfs]
        end

        def role
          params.role.try(:downcase).try(:to_sym) || :all
        end
      end

      after do
        header 'Cache-Control', 'max-age=3600'
      end

      group do
        resource :case_types do
          desc 'Return all Case Types'
          params { use :role_filter }
          get { present CaseType.__send__(role), with: API::Entities::CaseType }
        end

        resource :courts do
          desc 'Return all Courts'
          get { present Court.all, with: API::Entities::Court }
        end

        resource :advocate_categories do
          # TODO: this might need to be changed given there's a different list
          # of advocate categories depending on the fee scheme in use
          desc 'Return all Advocate Categories'
          get { Settings.advocate_categories }
        end

        resource :trial_cracked_at_thirds do
          desc 'Return all Trial Cracked at Third values (i.e. first, second, final)'
          get { Settings.trial_cracked_at_third }
        end

        resource :offence_classes do
          desc 'Return all Offence Class Types, with the matching offence_id for LGFS claims.'
          get { present OffenceClass.all, with: API::Entities::OffenceClass }
        end

        resource :offences do
          desc 'Return all Offence-ids to be used in advocate claims (see OffenceClasses for Litigator claims).'
          params do
            optional :offence_description, type: String, desc: 'Offences matching description'
          end
          get do
            offences = if params[:offence_description].present?
                         Offence.where(description: params[:offence_description])
                       else
                         Offence.all
                       end

            present offences, with: API::Entities::Offence
          end
        end

        resource :fee_types do
          helpers do
            def category
              params.category.try(:downcase)
            end
          end

          params do
            category_types = %w[all basic misc fixed graduated interim transfer warrant].to_sentence
            use :role_filter
            optional  :category,
                      type: String,
                      default: 'all',
                      values: %w[all basic misc fixed graduated interim transfer warrant],
                      desc: "OPTIONAL: The fee category to filter the results. Can be: #{category_types}. Default: all"
          end

          desc 'Return all AGFS Fee Types (optional category filter).'
          get do
            fee_types = if category.blank? || category == 'all'
                          Fee::BaseFeeType.__send__(role)
                        else
                          Fee::BaseFeeType.__send__(category).__send__(role)
                        end

            present fee_types, with: API::Entities::BaseFeeType
          end
        end

        resource :expense_types do
          desc 'Return all Expense Types.'
          params { use :role_filter }
          get { present ExpenseType.__send__(role), with: API::Entities::ExpenseType }
        end

        resource :expense_reasons do
          desc 'Return all Expense Reasons by reason set.'
          get { present ExpenseType.reason_sets, with: API::Entities::ExpenseReasonSet }
        end

        resource :disbursement_types do
          desc 'Return all Disbursement Types.'
          get { present DisbursementType.active, with: API::Entities::DisbursementType }
        end

        resource :transfer_stages do
          desc 'Return all Transfer Stages'
          get { present ::Claim::TransferBrain::TRANSFER_STAGES.to_a, with: API::Entities::SimpleKeyValueList }
        end

        resource :transfer_case_conclusions do
          desc 'Return all Transfer Case Conclusions'
          get { present ::Claim::TransferBrain::CASE_CONCLUSIONS.to_a, with: API::Entities::SimpleKeyValueList }
        end
      end
    end
  end
end
