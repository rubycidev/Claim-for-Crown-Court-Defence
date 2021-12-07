# frozen_string_literal: true

RSpec.shared_examples 'a base count query' do
  describe '.call' do
    subject(:call) { described_class.call(kwargs) }

    let(:kwargs) { { date_range: Time.zone.today..Time.zone.today, date_column_filter: :bar } }

    let(:instance) { instance_double(described_class) }
    let(:result) { instance_double(PG::Result) }

    before do
      allow(described_class).to receive(:new).with(any_args).and_return(instance)
      allow(instance).to receive(:call).and_return(result)
    end

    it 'sends \'new\' with arguments' do
      call
      expect(described_class).to have_received(:new).with(hash_including(:date_range, :date_column_filter))
    end

    it 'sends \'call\' to instance of class' do
      call
      expect(instance).to have_received(:call)
    end
  end

  describe '#call' do
    subject(:call) { described_class.new(kwargs).call }

    let(:date_range) { Time.zone.today..Time.zone.today }

    context 'with valid date_range and date_column_filter' do
      let(:kwargs) { { date_range: date_range, date_column_filter: :originally_submitted_at } }

      it 'returned object behaves like array' do
        is_expected.to respond_to(:[])
      end

      it 'returned object has only one element' do
        expect(call.count).to be(1)
      end

      it 'first returned object has a "count" key' do
        expect(call.first.key?('count')).to be true
      end

      it 'first returned object "count" is integer' do
        expect(call.first['count']).to be_an(Integer)
      end
    end

    context 'with date_range as Date objects' do
      let(:kwargs) do
        { date_range: Date.parse('2021-01-01')..Date.parse('2021-01-01'),
          date_column_filter: :originally_submitted_at }
      end

      it { expect { call }.not_to raise_error }
    end

    context 'with date_range string' do
      let(:kwargs) do
        { date_range: '2021-13-01'..Date.parse('2021-01-01'),
          date_column_filter: :originally_submitted_at }
      end

      it { expect { call }.to raise_error ArgumentError, /bad value for range/ }
    end

    context 'without date_range key' do
      let(:kwargs) { { date_column_filter: :originally_submitted_at } }

      it { expect { call }.to raise_error ArgumentError, /missing keyword.*date_range/ }
    end

    context 'without date_column_filter' do
      let(:kwargs) { { date_range: Time.zone.today..Time.zone.today } }

      it { expect { call }.to raise_error ArgumentError, /missing keyword.*date_column_filter/ }
    end

    context 'when trying to inject SQL' do
      let(:kwargs) do
        { date_range: Time.zone.today..Time.zone.today,
          date_column_filter: 'originally_submitted_at; (select PG_SLEEP(15))' }
      end

      it { expect { call }.to raise_error ActiveRecord::StatementInvalid }
    end
  end
end

RSpec.shared_examples 'an originally_submitted_at filterable query' do
  describe '#call' do
    subject(:result) { described_class.new(kwargs).call }

    let(:kwargs) { { date_range: date_range, date_column_filter: :originally_submitted_at } }

    before { claim }

    context 'with submissions on day' do
      let(:date_range) { Time.zone.today..Time.zone.today }

      it { expect(result.first['count']).to eq(1) }
    end

    context 'without submissions on day' do
      let(:date_range) { 1.day.ago..1.day.ago }

      it { expect(result.first['count']).to eq(0) }
    end
  end
end

RSpec.shared_examples 'a completed_at filterable query' do
  describe '#call' do
    subject(:result) { described_class.new(kwargs).call }

    let(:kwargs) { { date_range: date_range, date_column_filter: :completed_at } }

    before { claim }

    context 'with completions on day' do
      let(:date_range) { Time.zone.today..Time.zone.today }

      it { expect(result.first['count']).to eq(1) }
    end

    context 'without completions on day' do
      let(:date_range) { 1.day.ago..1.day.ago }

      it { expect(result.first['count']).to eq(0) }
    end
  end
end