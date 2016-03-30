require 'rails_helper'
require 'custom_matchers'

RSpec.describe ExternalUsers::Advocates::ClaimsController, type: :controller, focus: true do

  let!(:advocate)       { create(:external_user, :advocate) }
  before { sign_in advocate.user }

  describe "GET #new" do
    context 'AGFS or LGFS provider members only' do
      before { get :new }
      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it 'assigns @claim' do
        expect(assigns(:claim)).to be_new_record
      end

      it 'assigns @claim to be an advocate claim' do
        expect(assigns(:claim)).to be_instance_of Claim::AdvocateClaim
      end

      it 'renders the template' do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST #create" do
    context 'when advocate signed in' do
      context 'and the input is valid' do
        let(:court)         { create(:court) }
        let(:offence)       { create(:offence) }
        let(:case_type)     { create(:case_type) }
        let(:expense_type)  { create(:expense_type, :car_travel) }
        let(:claim_params) do
          {
            claim_class: 'Claim::AdvocateClaim',
            additional_information: 'foo',
            court_id: court,
            case_type_id: case_type.id,
            offence_id: offence,
            case_number: 'A12345678',
            advocate_category: 'QC',
            expenses_attributes:
              [
                expense_attributes_for(expense_type)
              ],
            defendants_attributes: [
              { first_name: 'John',
                last_name: 'Smith',
                date_of_birth_dd: '4',
                date_of_birth_mm: '10',
                date_of_birth_yyyy: '1980',
                representation_orders_attributes: [
                  {
                    representation_order_date_dd: Time.now.day.to_s,
                    representation_order_date_mm: Time.now.month.to_s,
                    representation_order_date_yyyy: Time.now.year.to_s,
                    maat_reference: '4561237895'
                  }
                ]
              }
            ]
          }
        end

        context 'create draft' do
          it 'creates a claim' do
            expect {
              post :create, commit: 'Save to drafts', claim: claim_params
            }.to change(Claim::AdvocateClaim, :count).by(1)
          end

          it 'redirects to claims list' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(response).to redirect_to(external_users_claims_path)
          end

          it 'sets the created claim\'s external_user/"owner" to the signed in advocate' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(Claim::AdvocateClaim.first.external_user).to eq(advocate)
            expect(Claim::AdvocateClaim.first.creator).to eq(advocate)
          end

          it 'sets the claim\'s state to "draft"' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(Claim::AdvocateClaim.first).to be_draft
          end
        end

        context 'submit to LAA' do
          it 'creates a claim' do
            expect {
              post :create, commit: 'Submit to LAA', claim: claim_params
            }.to change(Claim::AdvocateClaim, :count).by(1)
          end

          it 'redirects to claim summary if no validation errors present' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(response).to redirect_to(summary_external_users_claim_path(Claim::AdvocateClaim.first))
          end

          it 'sets the created claim\'s external_user/owner to the signed in advocate' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(Claim::AdvocateClaim.first.external_user).to eq(advocate)
            expect(Claim::AdvocateClaim.first.creator).to eq(advocate)
          end

          it 'leaves the claim\'s state in "draft"' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(response).to have_http_status(:redirect)
            expect(Claim::AdvocateClaim.first).to be_draft
          end
        end

      end

      context 'submit to LAA with incomplete/invalid params' do
        let(:invalid_claim_params)      { { claim_class: 'Claim::AdvocateClaim' } }
        it 'does not create a claim' do
          expect {
            post :create, claim: invalid_claim_params, commit: 'Submit to LAA'
          }.to_not change(Claim::AdvocateClaim, :count)
        end

        it 'renders the new template' do
          post :create, claim: invalid_claim_params, commit: 'Submit to LAA'
          expect(response).to render_template(:new)
        end
      end

      context 'basic and non-basic fees' do

        let!(:basic_fee_type_1)         { FactoryGirl.create :basic_fee_type, description: 'Basic Fee Type 1' }
        let!(:basic_fee_type_2)         { FactoryGirl.create :basic_fee_type, description: 'Basic Fee Type 2' }
        let!(:basic_fee_type_3)         { FactoryGirl.create :basic_fee_type, description: 'Basic Fee Type 3' }
        let!(:basic_fee_type_4)         { FactoryGirl.create :basic_fee_type, description: 'Basic Fee Type 4' }
        let!(:misc_fee_type_1)          { FactoryGirl.create :misc_fee_type, description: 'Miscellaneous Fee Type 1' }
        let!(:misc_fee_type_2)          { FactoryGirl.create :misc_fee_type, description: 'Miscellaneous Fee Type 2' }
        let!(:fixed_fee_type_1)         { FactoryGirl.create :fixed_fee_type, description: 'Fixed Fee Type 1' }

        let(:court)                     { create(:court) }
        let(:offence)                   { create(:offence) }
        let(:claim_params)              { valid_claim_fee_params }
        let(:invalid_claim_params)      { valid_claim_fee_params.reject{ |k,v| k == 'advocate_category'} }

        context 'non fixed fee case types' do
          before(:each) do
            @file = fixture_file_upload('files/repo_order_1.pdf', 'application/pdf')
          end

          context 'valid params' do
            it 'should create a claim with all basic fees and specified miscellaneous but NOT the fixed fees' do
              post :create, claim: claim_params
              claim = assigns(:claim)

              # one record for every basic fee regardless of whether blank or not
              expect(claim.basic_fees.size).to eq 4
              expect(claim.basic_fees.detect{ |f| f.fee_type_id == basic_fee_type_1.id }.amount.to_f ).to eq 1000
              expect(claim.basic_fees.detect{ |f| f.fee_type_id == basic_fee_type_3.id }.amount.to_f ).to eq 9000.45
              expect(claim.basic_fees.detect{ |f| f.fee_type_id == basic_fee_type_4.id }.amount.to_f ).to eq 125.0
              expect(claim.basic_fees.detect{ |f| f.fee_type_id == basic_fee_type_2.id }).to be_blank

              # fixed fees are deleted implicitly by claim model for non-fixed-fee case types
              expect(claim.fixed_fees.size).to eq 0

              expect(claim.misc_fees.size).to eq 1
              expect(claim.misc_fees.detect{ |f| f.fee_type_id == misc_fee_type_2.id }.amount.to_f ).to eq 250.0

              expect(claim.reload.fees_total).to eq 10_375.45
            end
          end

          context 'invalid params' do
            render_views
            it 'should redisplay the page with error messages and all the entered data in basic, miscellaneous and fixed fees' do
              post :create, claim: invalid_claim_params, commit: 'Submit to LAA'
              expect(response.status).to eq 200
              expect(response).to render_template(:new)
              expect(response.body).to have_content("Choose an advocate category")
              claim = assigns(:claim)
              expect(claim.basic_fees.size).to eq 4
              expect(claim.fixed_fees.size).to eq 1
              expect(claim.misc_fees.size).to eq 1

              bf1 = claim.basic_fees.detect{ |f| f.description == 'Basic Fee Type 1' }
              expect(bf1.quantity).to eq 10
              expect(bf1.amount).to eq 1000

              bf2 = claim.basic_fees.detect{ |f| f.description == 'Basic Fee Type 2' }
              expect(bf2.quantity).to eq 0
              expect(bf2.amount).to eq 0

              bf3 = claim.basic_fees.detect{ |f| f.description == 'Basic Fee Type 3' }
              expect(bf3.quantity).to eq 1
              expect(bf3.amount.to_f).to eq 9000.45

              bf4 = claim.basic_fees.detect{ |f| f.description == 'Basic Fee Type 4' }
              expect(bf4.quantity).to eq 5
              expect(bf4.amount).to eq 125
            end
          end
        end

        context 'fixed fee case types' do
          context 'valid params' do
            it 'should create a claim with fixed fees ONLY' do
              claim_params['case_type_id'] = FactoryGirl.create(:case_type, :fixed_fee).id.to_s
              response = post :create, claim: claim_params
              claim = assigns(:claim)

              # basic fees are cleared, but not destroyed, implicitly for fixed-fee case types
              expect(claim.basic_fees.size).to eq 4
              expect(claim.basic_fees.map(&:amount).sum).to eql 0.00

              # miscellaneous fees are NOT destroyed implicitly by claim model for fixed-fee case types
              expect(claim.misc_fees.size).to eq 1
              expect(claim.fixed_fees.size).to eq 1
              expect(claim.fixed_fees.map(&:amount).sum).to eql 2500.00

              expect(claim.reload.fees_total).to eq 2750.00
            end
          end
        end

      end

      context 'document checklist' do
        let(:court)             { create(:court) }
        let(:offence)           { create(:offence) }
        let(:case_type)         { create(:case_type) }
        let(:claim_params) do
          {
             additional_information: 'foo',
             court_id: court,
             case_type_id: case_type.id,
             offence_id: offence,
             case_number: '12345',
             advocate_category: 'QC',
             evidence_checklist_ids:  ['2', '3', '']
          }
        end

        it 'should create a claim with document checklist items' do
          post :create, claim: claim_params
          claim = assigns(:claim)
          expect(claim.evidence_checklist_ids).to eql( [ 2, 3 ] )
        end
      end

    end
  end

  def valid_claim_fee_params
  case_type = FactoryGirl.create :case_type
  HashWithIndifferentAccess.new(
    {
     "source" => 'web',
     "external_user_id" => "4",
     "case_type_id" => case_type.id.to_s,
     "court_id" => court.id.to_s,
     "case_number" => "CASE98989",
     "advocate_category" => "QC",
     "offence_class_id" => "2",
     "offence_id" => offence.id.to_s,
     "first_day_of_trial_dd" => '13',
     "first_day_of_trial_mm" => '5',
     "first_day_of_trial_yyyy" => '2015',
     "estimated_trial_length" => "2",
     "actual_trial_length" => "2",
     "trial_concluded_at_dd" => "15",
     "trial_concluded_at_mm" => "05",
     "trial_concluded_at_yyyy" => "2015",
     "evidence_checklist_ids" => ["1", "5", ""],
     "defendants_attributes"=>
      {"0"=>
        {"first_name" => "Stephen",
         "last_name" => "Richards",
         "date_of_birth_dd" => "13",
         "date_of_birth_mm" => "08",
         "date_of_birth_yyyy" => "1966",
         "_destroy" => "false",
         "representation_orders_attributes"=>{
           "0"=>{
             "representation_order_date_dd" => "13",
             "representation_order_date_mm" => "05",
             "representation_order_date_yyyy" => "2015",
             "maat_reference" => "1594851269",
           }
          }
        }
      },
     "additional_information" => "",
     "basic_fees_attributes"=>
      {
        "0"=>{"quantity" => "10", "rate" => "100", "fee_type_id" => basic_fee_type_1.id.to_s},
        "1"=>{"quantity" => "0", "rate" => "0.00", "fee_type_id" => basic_fee_type_2.id.to_s},
        "2"=>{"quantity" => "1", "rate" => "9000.45", "fee_type_id" => basic_fee_type_3.id.to_s},
        "3"=>{"quantity" => "5", "rate" => "25", "fee_type_id" => basic_fee_type_4.id.to_s}
        },
      "fixed_fees_attributes"=>
      {
        "0"=>{"fee_type_id" => fixed_fee_type_1.id.to_s, "quantity" => "250", "rate" => "10", "_destroy" => "false"}
      },
      "misc_fees_attributes"=>
      {
        "1"=>{"fee_type_id" => misc_fee_type_2.id.to_s, "quantity" => "2", "rate" => "125", "_destroy" => "false"},
      },
     "expenses_attributes"=>
     {
      "0"=>{"expense_type_id" => "", "location" => "", "quantity" => "", "rate" => "", "amount" => "", "_destroy" => "false"}
     },
     "apply_vat" => "0"
   }
   )
  end

end
