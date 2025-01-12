# == Schema Information
#
# Table name: external_users
#
#  id              :integer          not null, primary key
#  created_at      :datetime
#  updated_at      :datetime
#  supplier_number :string
#  uuid            :uuid
#  vat_registered  :boolean          default(TRUE)
#  provider_id     :integer
#  roles           :string
#  deleted_at      :datetime
#

require 'rails_helper'
require 'support/shared_examples_for_claim_types'
require 'support/shared_examples_for_users'

RSpec.describe ExternalUser do
  it_behaves_like 'roles', described_class, described_class::ROLES

  it { is_expected.to belong_to(:provider) }
  it { is_expected.to have_many(:claims) }
  it { is_expected.to have_many(:claims_created) }
  it { is_expected.to have_many(:documents) }
  it { is_expected.to have_one(:user) }

  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to validate_presence_of(:user) }

  it { is_expected.to accept_nested_attributes_for(:user) }

  it { is_expected.to delegate_method(:email).to(:user) }
  it { is_expected.to delegate_method(:first_name).to(:user) }
  it { is_expected.to delegate_method(:last_name).to(:user) }
  it { is_expected.to delegate_method(:name).to(:user) }
  it { is_expected.to delegate_method(:agfs?).to(:provider) }
  it { is_expected.to delegate_method(:lgfs?).to(:provider) }

  it_behaves_like 'a disablable delegator', :user

  describe 'supplier number validation' do
    subject(:external_user) { build(:external_user, provider:, supplier_number:) }

    context 'when Provider present and Provider is a "firm"' do
      let!(:provider) { create(:provider, :agfs_lgfs, firm_agfs_supplier_number: 'ZZ123') }
      let(:supplier_number) { nil }

      before do
        external_user.provider = provider
      end

      it { is_expected.not_to validate_presence_of(:supplier_number) }

      context 'with an advocate' do
        before { external_user.roles = ['advocate'] }

        it 'is valid without a supplier number' do
          a = build(:external_user, :advocate, provider:, supplier_number: nil)
          expect(a).to be_valid
        end
      end

      context 'with an admin' do
        before { external_user.roles = ['admin'] }

        it { is_expected.not_to validate_presence_of(:supplier_number) }

        it 'is valid without a supplier number' do
          a = build(:external_user, :admin, provider:, supplier_number: nil)
          expect(a).to be_valid
        end
      end
    end

    context 'when provider present and Provider is a "chamber"' do
      subject(:external_user) { build(:external_user, provider:, supplier_number:) }

      let(:supplier_number) { 'AC123' }
      let(:provider) { create(:provider, provider_type: 'chamber', firm_agfs_supplier_number: '') }

      context 'with an advocate' do
        subject(:external_user) { build(:external_user, provider:, supplier_number:) }

        before do
          external_user.roles = ['advocate']
          external_user.valid?
        end

        let(:format_error) { ['Enter a valid supplier number'] }

        it { is_expected.to validate_presence_of(:supplier_number) }

        context 'when the supplier number is blank' do
          let(:supplier_number) { nil }

          it { is_expected.not_to be_valid }
          it { expect(external_user.errors[:supplier_number]).to eq(['Enter a supplier number']) }
        end

        context 'when the supplier number is too long' do
          let(:supplier_number) { 'ACC123' }

          it { is_expected.not_to be_valid }
          it { expect(external_user.errors[:supplier_number]).to eq(format_error) }
        end

        context 'when the supplier number is too short' do
          let(:supplier_number) { 'AC1' }

          it { is_expected.not_to be_valid }
          it { expect(external_user.errors[:supplier_number]).to eq(format_error) }
        end

        context 'when the supplier number is not alpha-numeric' do
          let(:supplier_number) { 'AC-12' }

          it { is_expected.not_to be_valid }
          it { expect(external_user.errors[:supplier_number]).to eq(format_error) }
        end

        context 'when the supplier number is 5 characters alpha-numeric' do
          it { is_expected.to be_valid }
        end
      end

      context 'with an admin' do
        before { external_user.roles = ['admin'] }

        it { is_expected.not_to validate_presence_of(:supplier_number) }

        context 'when the supplier number is blank' do
          let(:supplier_number) { nil }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '#name' do
    subject(:name) { external_user.name }

    let(:external_user) { create(:external_user, user:) }
    let(:user) { create(:user, first_name: 'Tom', last_name: 'Cobley') }

    it { is_expected.to eq 'Tom Cobley' }
  end

  describe 'ROLES' do
    it 'has "admin" and "advocate" and "litigator"' do
      expect(ExternalUser::ROLES).to match_array(%w[admin advocate litigator])
    end
  end

  # Scopes from Roles module
  describe '.admins' do
    subject { described_class.admins }

    context 'with an admin user' do
      let!(:external_user) { create(:external_user, :admin) }

      it { is_expected.to eq [external_user] }
    end

    context 'with an advocate user' do
      before { create(:external_user, :advocate) }

      it { is_expected.to be_empty }
    end

    context 'with a user that is both admin and advocate' do
      let!(:external_user) { create(:external_user, :advocate) }

      before do
        external_user.roles = %w[admin advocate]
        external_user.save!
      end

      it { is_expected.to eq [external_user] }
    end
  end

  describe '.advocates' do
    subject { described_class.advocates }

    context 'with an admin user' do
      before { create(:external_user, :admin) }

      it { is_expected.to be_empty }
    end

    context 'with an advocate user' do
      let!(:external_user) { create(:external_user, :advocate) }

      it { is_expected.to eq [external_user] }
    end

    context 'with a user that is both admin and advocate' do
      let!(:external_user) { create(:external_user, :advocate) }

      before do
        external_user.roles = %w[admin advocate]
        external_user.save!
      end

      it { is_expected.to eq [external_user] }
    end
  end
  # End of scopes from Roles module

  # Methods from Roles module
  describe '#is?' do
    subject { user.is?(role) }

    context 'with an advocate user' do
      let(:user) { create(:external_user, :advocate) }

      context 'when testing for advocate' do
        let(:role) { :advocate }

        it { is_expected.to be_truthy }
      end

      context 'when testing for admin' do
        let(:role) { :admin }

        it { is_expected.to be_falsey }
      end
    end

    context 'with an admin user' do
      let(:user) { create(:external_user, :admin) }

      context 'when testing for advocate' do
        let(:role) { :advocate }

        it { is_expected.to be_falsey }
      end

      context 'when testing for admin' do
        let(:role) { :admin }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#advocate?' do
    subject { user.advocate? }

    context 'with an advocate user' do
      let(:user) { create(:external_user, :advocate) }

      it { is_expected.to be_truthy }
    end

    context 'with an admin user' do
      let(:user) { create(:external_user, :admin) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#admin?' do
    subject { user.admin? }

    context 'with an advocate user' do
      let(:user) { create(:external_user, :advocate) }

      it { is_expected.to be_falsey }
    end

    context 'with an admin user' do
      let(:user) { create(:external_user, :admin) }

      it { is_expected.to be_truthy }
    end
  end
  # End of methods from Roles module

  describe '#available_claim_types' do
    subject { user.available_claim_types.map(&:to_s) }

    include_context 'claim-types object helpers'

    context 'when the user has only an advocate role' do
      let(:user) { build(:external_user, :advocate) }

      it { is_expected.to match_array(agfs_claim_object_types) }
    end

    context 'when the user has only a litigator role' do
      let(:user) { build(:external_user, :litigator) }

      it { is_expected.to match_array(lgfs_claim_object_types) }
    end

    context 'when the user has an admin role' do
      let(:user) { build(:external_user, :admin, provider: build(:provider, :agfs)) }

      # TODO: i believe this is flawed as an admin should delegate available claim types to the provider)
      # e.g. an admin in an agfs only provider can only create advocate claims
      it { is_expected.to match_array(all_claim_object_types) }
    end

    context 'when the user has both advocate and litigator file in provider with both agfs and lgfs role' do
      let(:user) { build(:external_user, :advocate_litigator) }

      it { is_expected.to match_array(all_claim_object_types) }
    end
  end

  describe '#available_roles' do
    subject { user.available_roles }

    let(:user) { create(:external_user, :advocate, provider:) }

    context "when the user's provider handles both AGFS and LGFS claims" do
      let(:provider) { build(:provider, :agfs_lgfs) }

      it { is_expected.to match_array %w[admin advocate litigator] }
    end

    context "when the user's provider handles only AGFS claims" do
      let(:provider) { build(:provider, :agfs) }

      it { is_expected.to match_array %w[admin advocate] }
    end

    context "when the user's provider handles only LGFS claims" do
      let(:provider) { build(:provider, :lgfs) }

      it { is_expected.to match_array %w[admin litigator] }
    end

    context 'when an invalid role supplied' do
      let(:provider) { build(:provider) }

      before { user.provider.roles = %w[invalid_role] }

      it 'raises an error' do
        expect { user.available_roles }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#name_and_number' do
    it 'returns last name, first name and supplier number' do
      a = create(:external_user, supplier_number: 'XX878', user: create(:user, last_name: 'Smith', first_name: 'John'))
      expect(a.name_and_number).to eq 'Smith, John (XX878)'
    end
  end

  it_behaves_like 'user model with default, active and softly deleted scopes' do
    let(:live_users) { create_list(:external_user, 2) }
    let(:dead_users) { create_list(:external_user, 2, :softly_deleted) }
  end

  describe '#soft_delete' do
    subject(:soft_delete) { external_user.soft_delete }

    let(:external_user) { create(:external_user) }

    it { expect { soft_delete }.to change(external_user, :deleted_at).from(nil) }
    it { expect { soft_delete }.to change(external_user.user, :deleted_at).from(nil) }
  end

  describe '#active?' do
    it 'returns false for deleted records' do
      eu = build(:external_user, :softly_deleted)
      expect(eu.active?).to be false
    end

    it 'returns true for active records' do
      eu = build(:external_user)
      expect(eu.active?).to be true
    end
  end

  describe '#supplier_number' do
    subject { external_user.supplier_number }

    context 'with a supplier number' do
      let(:external_user) { create(:external_user, :advocate, supplier_number: 'ZZ114') }

      it { is_expected.to eq 'ZZ114' }
    end

    context 'when the supplier number set in the provider' do
      let(:provider) { create(:provider, :agfs_lgfs, firm_agfs_supplier_number: '999XX') }
      let(:external_user) { create(:external_user, :advocate, supplier_number: nil, provider:) }

      it { is_expected.to eq '999XX' }
    end
  end

  describe '#send_email_notification_of_message?' do
    subject { external_user.send_email_notification_of_message? }

    let(:external_user) { build(:external_user) }

    it { is_expected.to be_falsey }

    context 'when email_notification_of_message is set to true by name' do
      before { external_user.email_notification_of_message = 'true' }

      it { is_expected.to be_truthy }
    end

    context 'when email_notification_of_message is set to false by name' do
      before { external_user.email_notification_of_message = 'false' }

      it { is_expected.to be_falsey }
    end

    context 'when email_notification_of_message is set to true in settings' do
      before { external_user.save_settings!(email_notification_of_message: true) }

      it { is_expected.to be_truthy }
    end

    context 'when email_notification_of_message is set to false in settings' do
      before { external_user.save_settings!(email_notification_of_message: false) }

      it { is_expected.to be_falsey }
    end
  end
end
