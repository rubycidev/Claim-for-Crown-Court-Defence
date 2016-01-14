require 'rails_helper'
require 'custom_matchers'

RSpec.describe ExternalUsers::ClaimsController, type: :controller, focus: true do

  let!(:advocate)       { create(:external_user, :advocate) }
  let!(:advocate_admin) { create(:external_user, :admin, provider_id: advocate.provider.id) }

  before { sign_in advocate.user }

  describe '#GET index' do

    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'renders the template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'should retrieve dashboard displayable state claims for the advocate' do
      get :index
      expect(assigns(:context)).to eq(advocate.user)
    end

    context 'advocate admin' do
      before { sign_in advocate_admin.user }
      it 'should retrieve dashboard displayable state claims for the provider' do
        get :index
        expect(assigns(:context)).to eq(advocate_admin.provider)
      end
    end

    context "sorting" do
      before(:each) do
        create_list(:draft_claim, 1, external_user: advocate)
        create_list(:draft_claim, 1, external_user: advocate, created_at: 5.days.ago)
        create_list(:draft_claim, 6, external_user: advocate, created_at: 1.day.ago)
        create_list(:draft_claim, 1, external_user: advocate, created_at: 2.days.ago)
        create(:submitted_claim, external_user: advocate).update_column(:last_submitted_at, 1.day.ago)
        create(:refused_claim, external_user: advocate).update_column(:last_submitted_at, 2.days.ago)
        get :index
      end

      it 'orders claims with draft first (oldest created first) then oldest submitted' do
        expect(assigns(:claims)).to eq(advocate.claims.dashboard_displayable_states.sort('last_submitted_at', 'asc').page(1).per(10))
      end

      it 'paginates to 10 per page' do
        expect(assigns(:claims).count).to eq(10)
      end
    end
  end

  describe '#GET archived' do

    it 'returns success' do
      get :archived
      expect(response).to have_http_status(:success)
    end

    it 'renders the template' do
      get :archived
      expect(response).to render_template(:archived)
    end

    it 'should assign context for claims to advocate' do
      get :index
      expect(assigns(:context)).to eq(advocate.user)
    end

    context 'advocate admin' do
      before { sign_in advocate_admin.user }
      it 'should assign context for claims to provider' do
        get :index
        expect(assigns(:context)).to eq(advocate_admin.provider)
      end
    end

    context "sorting" do
      before(:each) do
        create_list(:archived_pending_delete_claim, 8, external_user: advocate).each { |c| c.update_column(:last_submitted_at, 8.days.ago) }
        create(:archived_pending_delete_claim, external_user: advocate).update_column(:last_submitted_at, 3.days.ago)
        create(:archived_pending_delete_claim, external_user: advocate).update_column(:last_submitted_at, 1.day.ago)
        create(:archived_pending_delete_claim, external_user: advocate).update_column(:last_submitted_at, 2.days.ago)
        get :archived
      end

      it 'orders claims with most recently submitted first' do
        expect(assigns(:claims)).to eq(advocate.claims.archived_pending_delete.sort('last_submitted_at', 'desc').page(1).per(10))
      end

      it 'paginates to 10 per page' do
        expect(assigns(:claims).count).to eq(10)
      end
    end
  end

  describe "GET #show" do
    subject { create(:claim, external_user: advocate) }

    it "returns http success" do
      get :show, id: subject
      expect(response).to have_http_status(:success)
    end

    it 'assigns @claim' do
      get :show, id: subject
      expect(assigns(:claim)).to eq(subject)
    end

    it 'renders the template' do
      get :show, id: subject
      expect(response).to render_template(:show)
    end

    it 'automatically marks unread messages on claim for current user as "read"' do
      message_1 = create(:message, claim_id: subject.id, sender_id: advocate.user.id)
      message_2 = create(:message, claim_id: subject.id, sender_id: advocate.user.id)
      message_3 = create(:message, claim_id: subject.id, sender_id: advocate.user.id)

      expect(subject.unread_messages_for(advocate.user).count).to eq(3)

      get :show, id: subject

      expect(subject.unread_messages_for(advocate.user).count).to eq(0)
    end
  end

  describe "GET #new" do
    before { get :new }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it 'assigns @claim' do
      expect(assigns(:claim)).to be_new_record
    end

    it 'renders the template' do
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    before { get :edit, id: subject }

    context 'editable claim' do
      subject { create(:claim, external_user: advocate) }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it 'assigns @claim' do
        expect(assigns(:claim)).to eq(subject)
      end

      it 'renders the template' do
        expect(response).to render_template(:edit)
      end
    end

    context 'uneditable claim' do
      subject { create(:allocated_claim, external_user: advocate) }

      it 'redirects to advocates claims index' do
        expect(response).to redirect_to(external_users_claims_url)
      end
    end
  end

  describe "POST #create" do
    context 'when advocate signed in' do
      context 'and the input is valid' do
        let(:court)         { create(:court) }
        let(:offence)       { create(:offence) }
        let(:case_type)     { create(:case_type) }
        let(:expense_type)  { create(:expense_type) }
        let(:claim_params) do
          {
            additional_information: 'foo',
            court_id: court,
            case_type_id: case_type.id,
            offence_id: offence,
            case_number: 'A12345678',
            advocate_category: 'QC',
            expenses_attributes:
              [
                {
                  expense_type_id: expense_type.id,
                  location: "London",
                  quantity: 1,
                  rate: 40
                }
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

        context 'submit to LAA' do
          it 'creates a claim' do
            expect {
              post :create, commit: 'Submit to LAA', claim: claim_params
            }.to change(Claim, :count).by(1)
          end

          it 'redirects to claim certification if no validation errors' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(response).to redirect_to(new_external_users_claim_certification_path(Claim.first))
          end

          it 'sets the created claim\'s advocate to the signed in advocate' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(Claim.first.external_user).to eq(advocate)
          end

          it 'leaves the claim\'s state in "draft"' do
            post :create, claim: claim_params, commit: 'Submit to LAA'
            expect(response).to have_http_status(:redirect)
            expect(Claim.first).to be_draft
          end
        end

        context 'create draft' do
          it 'creates a claim' do
            expect {
              post :create, commit: 'Save to drafts', claim: claim_params
            }.to change(Claim, :count).by(1)
          end

          it 'redirects to claims list' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(response).to redirect_to(external_users_claims_path)
          end

          it 'sets the created claim\'s advocate to the signed in advocate' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(Claim.first.external_user).to eq(advocate)
          end

          it 'sets the claim\'s state to "draft"' do
            post :create, claim: claim_params, commit: 'Save to drafts'
            expect(Claim.first).to be_draft
          end
        end
      end

      context 'submit to LAA with incomplete/invalid params' do
        it 'does not create a claim' do
          expect {
            post :create, claim: { additional_information: 'foo' }, commit: 'Submit to LAA'
          }.to_not change(Claim, :count)
        end

        it 'renders the new template' do
          post :create, claim: { additional_information: 'foo' }, commit: 'Submit to LAA'
          expect(response).to render_template(:new)
        end
      end

      context 'basic and non-basic fees' do

        let!(:basic_fee_type_1)         { FactoryGirl.create :fee_type, :basic, description: 'Basic Fee Type 1' }
        let!(:basic_fee_type_2)         { FactoryGirl.create :fee_type, :basic, description: 'Basic Fee Type 2' }
        let!(:basic_fee_type_3)         { FactoryGirl.create :fee_type, :basic, description: 'Basic Fee Type 3' }
        let!(:basic_fee_type_4)         { FactoryGirl.create :fee_type, :basic, description: 'Basic Fee Type 4' }
        let!(:misc_fee_type_1)          { FactoryGirl.create :fee_type, :misc, description: 'Miscellaneous Fee Type 1' }
        let!(:misc_fee_type_2)          { FactoryGirl.create :fee_type, :misc, description: 'Miscellaneous Fee Type 2' }
        let!(:fixed_fee_type_1)         { FactoryGirl.create :fee_type, :fixed, description: 'Fixed Fee Type 1' }

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
              claim_params['case_type_id'] = CaseType.find_or_create_by!(name: 'Fixed fee', is_fixed_fee: true).id.to_s
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

  describe "PUT #update" do
    subject { create(:claim, external_user: advocate) }

    context 'when valid' do

      context 'and deleting a rep order' do
        before {
          put :update, id: subject, claim: { defendants_attributes: { '1' => { id: subject.defendants.first, representation_orders_attributes: {'0' => {id: subject.defendants.first.representation_orders.first, _destroy: 1}}}}}, commit: 'Save to drafts'
        }
        it 'reduces the number of associated rep order by 1' do
          expect(subject.reload.defendants.first.representation_orders.count).to eq 1
        end
      end

      context 'and editing an API created claim' do

        before(:each) do
          subject.update(source: 'api')
        end

        context 'and saving to draft' do
          before { put :update, id: subject, claim: { additional_information: 'foo' }, commit: 'Save to drafts' }
          it 'sets API created claims source to indicate it is from API but has been edited in web' do
            expect(subject.reload.source).to eql 'api_web_edited'
          end
        end

        context 'and submitted to LAA' do
          before { put :update, id: subject, claim: { additional_information: 'foo' }, summary: true, commit: 'Submit to LAA' }
          it 'sets API created claims source to indicate it is from API but has been edited in web' do
            expect(subject.reload.source).to eql 'api_web_edited'
          end
        end
      end

      context 'and saving to draft' do
        it 'updates a claim' do
          put :update, id: subject, claim: { additional_information: 'foo' }, commit: 'Save to drafts'
          subject.reload
          expect(subject.additional_information).to eq('foo')
        end

        it 'redirects to claims list path' do
          put :update, id: subject, claim: { additional_information: 'foo' }
          expect(response).to redirect_to(external_users_claims_path)
        end

      end

      context 'and submitted to LAA' do
        before do
          get :edit, id: subject
          put :update, id: subject, claim: { additional_information: 'foo' }, summary: true, commit: 'Submit to LAA'
        end

        it 'redirects to the claim confirmation path' do
          expect(response).to redirect_to(new_external_users_claim_certification_path(subject))
        end
      end
    end

    context 'when submitted to LAA and invalid ' do
      it 'does not set claim to submitted' do
        put :update, id: subject, claim: { court_id: nil }, commit: 'Submit to LAA'
        subject.reload
        expect(subject).to_not be_submitted
      end

      it 'renders edit template' do
        put :update, id: subject, claim: { additional_information: 'foo', court_id: nil }, commit: 'Submit to LAA'
        expect(response).to render_template(:edit)
      end
    end

    context 'Date Parameter handling' do
      it 'should transform dates with named months into dates' do
        put :update, id: subject, claim: {
          'first_day_of_trial_yyyy' => '2015',
          'first_day_of_trial_mm' => 'jan',
          'first_day_of_trial_dd' => '4' }, commit: 'Submit to LAA'
        expect(assigns(:claim).first_day_of_trial).to eq Date.new(2015, 1, 4)
      end

      it 'should transform dates with numbered months into dates' do
        put :update, id: subject, claim: {
          'first_day_of_trial_yyyy' => '2015',
          'first_day_of_trial_mm' => '11',
          'first_day_of_trial_dd' => '4' }, commit: 'Submit to LAA'
        expect(assigns(:claim).first_day_of_trial).to eq Date.new(2015, 11, 4)
      end
    end
  end

  describe "PATCH #clone_rejected" do
    context 'from rejected claim' do
      subject { create(:rejected_claim, external_user: advocate) }

      before do
        patch :clone_rejected, id: subject
      end

      it 'creates a draft from the rejected claim' do
        expect(Claim.last).to be_draft
        expect(Claim.last.case_number).to eq(subject.case_number)
      end

      it 'redirects to the draft\'s edit page' do
        expect(response).to redirect_to(edit_external_users_claim_url(Claim.last))
      end
    end

    context 'from non-rejected claim' do
      subject { create(:submitted_claim, external_user: advocate) }

      before do
        patch :clone_rejected, id: subject
      end

      it 'redirects to advocates dashboard' do
        expect(response).to redirect_to(external_users_claims_url)
      end

      it 'does not create a draft claim' do
        expect(Claim.last).to_not be_draft
      end
    end
  end

  describe "DELETE #destroy" do
    before { delete :destroy, id: subject }

    subject { create(:draft_claim, external_user: advocate) }

    context 'when draft claim' do
      it 'deletes the claim' do
        expect(Claim.count).to eq(0)
      end
    end

    context 'when non-draft claim' do
      subject { create(:submitted_claim, external_user: advocate) }

      it "sets the claim's state to 'archived_pending_delete'" do
        expect(Claim.count).to eq(1)
        claim = Claim.first
        expect(claim.state).to eq 'archived_pending_delete'
      end
    end

    it 'redirects to advocates root url' do
      expect(response).to redirect_to(external_users_claims_url)
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



def build_claim_in_state(state)
  claim = FactoryGirl.build :unpersisted_claim
  allow(claim).to receive(:state).and_return(state.to_s)
  claim
end
