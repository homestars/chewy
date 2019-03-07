require 'spec_helper'

if defined?(::ActiveJob)
  describe HSChewy::Strategy::ActiveJob do
    around { |example| HSChewy.strategy(:bypass) { example.run } }
    before(:all) do
      ::ActiveJob::Base.logger = HSChewy.logger
    end
    before do
      ::ActiveJob::Base.queue_adapter = :test
      ::ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      ::ActiveJob::Base.queue_adapter.performed_jobs.clear
    end

    before do
      stub_model(:city) do
        update_index('cities#city') { self }
      end

      stub_index(:cities) do
        define_type City
      end
    end

    let(:city) { City.create!(name: 'hello') }
    let(:other_city) { City.create!(name: 'world') }

    specify do
      expect { [city, other_city].map(&:save!) }
        .not_to update_index(CitiesIndex::City, strategy: :active_job)
    end

    specify do
      HSChewy.strategy(:active_job) do
        [city, other_city].map(&:save!)
      end
      enqueued_job = ::ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(enqueued_job[:job]).to eq(HSChewy::Strategy::ActiveJob::Worker)
      expect(enqueued_job[:queue]).to eq('chewy')
    end

    specify do
      ::ActiveJob::Base.queue_adapter = :inline
      expect { [city, other_city].map(&:save!) }
        .to update_index(CitiesIndex::City, strategy: :active_job)
        .and_reindex(city, other_city).only
    end

    specify do
      expect(CitiesIndex::City).to receive(:import!).with([city.id, other_city.id], suffix: '201601')
      HSChewy::Strategy::ActiveJob::Worker.new.perform('CitiesIndex::City', [city.id, other_city.id], suffix: '201601')
    end

    specify do
      allow(Chewy).to receive(:disable_refresh_async).and_return(true)
      expect(CitiesIndex::City).to receive(:import!).with([city.id, other_city.id], suffix: '201601', refresh: false)
      HSChewy::Strategy::ActiveJob::Worker.new.perform('CitiesIndex::City', [city.id, other_city.id], suffix: '201601')
    end
  end
end
