require_relative 'base_claim_test'

class LitigatorFinalClaimTest < BaseClaimTest
  def initialize(...)
    @claim_create_endpoint = 'claims/final'
    @email = LITIGATOR_TEST_EMAIL

    super
  end

  def test_creation!
    super

    # CREATE graduated fee
    client.post_to_endpoint('fees', graduated_fee_data)

    # CREATE miscellaneous fee
    client.post_to_endpoint('fees', misc_fee_data)

    # CREATE a warrant fee
    client.post_to_endpoint('fees', warrant_fee_data)

    # add expense
    client.post_to_endpoint('expenses', expense_data(role: 'lgfs'))

    # CREATE a disbursement
    client.post_to_endpoint('disbursements', disbursement_data)
  ensure
    clean_up
  end

  def claim_data
    case_type_id = json_value_at_index(client.get_dropdown_endpoint(CASE_TYPE_ENDPOINT, api_key, role: 'lgfs'), 'id', 12) # Trial
    offence_id = json_value_at_index(client.get_dropdown_endpoint(OFFENCE_ENDPOINT, api_key, offence_description: 'Miscellaneous/other'), 'id')
    court_id = json_value_at_index(client.get_dropdown_endpoint(COURT_ENDPOINT, api_key), 'id')

    {
      api_key:,
      creator_email: 'litigatoradmin@example.com',
      user_email: 'litigator@example.com',
      case_number: 'A20161234',
      providers_ref: SecureRandom.uuid[3..15].upcase,
      supplier_number:,
      case_type_id:,
      offence_id:,
      court_id:,
      cms_number: '12345678',
      additional_information: 'string',
      case_concluded_at: 1.month.ago.as_json,
      actual_trial_length: 10
    }
  end

  def graduated_fee_data
    fee_type_id = json_value_at_index(client.get_dropdown_endpoint(FEE_TYPE_ENDPOINT, api_key, category: 'graduated', role: 'lgfs'), 'id', 5) # Trial

    {
      api_key:,
      claim_id: @claim_uuid,
      fee_type_id:,
      quantity: 5,
      amount: 100.25,
      date: 1.month.ago.as_json
    }
  end

  def misc_fee_data
    fee_type_id = json_value_at_index(client.get_dropdown_endpoint(FEE_TYPE_ENDPOINT, api_key, category: 'misc', role: 'lgfs'), 'id') # Costs judge application

    {
      api_key:,
      claim_id: @claim_uuid,
      fee_type_id:,
      amount: 200.45
    }
  end
end
