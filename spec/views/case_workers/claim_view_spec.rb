require 'rails_helper'

describe 'case_workers/claims/show.html.haml', type: :view do

  include ViewSpecHelper

  before(:all) do
    @case_worker = create :case_worker
    @doc_types = DocType.all
  end

  after(:all) do
    clean_database
  end

  before(:each) do
    initialize_view_helpers(view)
    sign_in :user, @case_worker.user
    allow(view).to receive(:current_user_persona_is?).and_return(false)
    assign(:claim, @claim)
  end

  context 'certified claims' do
    before(:all) { certified_claim }

    it 'displays the name of the external user' do
      render
      expect(rendered).to include('Stepriponikas Bonstart')
    end

    it 'shows the reason for certification' do
      render
      expect(rendered).to include('which ever reason i please')
    end
  end

  context 'trial and retrial claims' do

    it 'shows trial details' do
      trial_claim
      assign(:claim, @claim)
      render
      expect(rendered).to have_content('First day of trial')
    end

    it 'shows retrial details' do
      trial_claim('re')
      assign(:claim, @claim)
      render
      expect(rendered).to have_content('First day of retrial')
    end

    describe 'document checklist' do
      let!(:claim_with_doc) { create :claim }
      let!(:document) { create :document, :verified, claim: claim_with_doc }

      before do
        allow(view).to receive(:current_user_persona_is?).with(CaseWorker).and_return(true)
        assign(:claim, claim_with_doc)
        render
      end

      it 'displays a `download all` link' do
        expect(rendered).to have_link('Download all')
      end
    end
  end


  def certified_claim
    @eu = create :external_user, :advocate, user: create(:user, first_name: 'Stepriponikas', last_name: 'Bonstart')
    @claim = create(:allocated_claim, external_user: @eu)
    @claim.certification.destroy unless @claim.certification.nil?
    certification_type = FactoryGirl.create(:certification_type, name: 'which ever reason i please')
    FactoryGirl.create(:certification, claim: @claim, certified_by: 'Bobby Legrand', certification_type: certification_type)
    @case_worker.claims << @claim
    @claim.reload
    @messages = @claim.messages.most_recent_last
    @message = @claim.messages.build

  end

  def trial_claim(trial_prefix = nil)
    @claim = create(:submitted_claim, case_type: FactoryGirl.create(:case_type, "#{trial_prefix}trial".to_sym), evidence_checklist_ids: [1, 9])
    @case_worker.claims << @claim
    @document = create(:document, claim_id: @claim.id, form_id: @claim.form_id)
    @messages = @claim.messages.most_recent_last
    @message = @claim.messages.build
  end
end
