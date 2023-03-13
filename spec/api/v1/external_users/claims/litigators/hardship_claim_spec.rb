require 'rails_helper'

RSpec.describe API::V1::ExternalUsers::Claims::Litigators::HardshipClaim do
  include Rack::Test::Methods
  include ApiSpecHelper

  LITIGATOR_HARDSHIP_CLAIM_ENDPOINT = 'litigators/hardship'.freeze

  subject(:post_to_validate_endpoint) do
    post ClaimApiEndpoints.for(LITIGATOR_HARDSHIP_CLAIM_ENDPOINT).validate, valid_params, format: :json
  end

  let(:claim_class) { Claim::LitigatorHardshipClaim }
  let!(:provider) { create(:provider, :lgfs) }
  let!(:other_provider) { create(:provider, :lgfs) }
  let!(:vendor) { create(:external_user, :admin, provider:) }
  let!(:litigator) { create(:external_user, :litigator, provider:) }
  let!(:other_vendor) { create(:external_user, :admin, provider: other_provider) }
  let!(:offence) { create(:offence, :miscellaneous) }
  let!(:court) { create(:court) }
  let!(:valid_params) do
    {
      api_key: provider.api_key,
      creator_email: vendor.user.email,
      user_email: litigator.user.email,
      supplier_number: provider.lgfs_supplier_numbers.first,
      case_stage_unique_code: create(:case_stage, :pre_ptph_or_ptph_adjourned).unique_code,
      case_number: 'A20201234',
      offence_id: offence.id,
      court_id: court.id,
      main_hearing_date: '2020-01-09'
    }
  end

  after(:all) { clean_database }

  include_examples 'litigator claim test setup'
  include_examples 'malformed or not iso8601 compliant dates', action: :validate, attributes: %i[main_hearing_date]
  include_examples 'optional parameter validation', optional_parameters: %i[main_hearing_date]
  it_behaves_like 'a claim endpoint', relative_endpoint: LITIGATOR_HARDSHIP_CLAIM_ENDPOINT
  it_behaves_like 'a claim validate endpoint', relative_endpoint: LITIGATOR_HARDSHIP_CLAIM_ENDPOINT
  it_behaves_like 'a claim create endpoint', relative_endpoint: LITIGATOR_HARDSHIP_CLAIM_ENDPOINT
end
