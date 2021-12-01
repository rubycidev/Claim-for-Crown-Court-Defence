require 'forwardable'

module ThinkstCanary
  class FactoryGenerator
    extend Forwardable

    def_delegator :configuration, :query

    def create_factory(memo:, flock_id:)
      params = { memo: memo, flock_id: flock_id }
      factory_auth = query(:post, '/api/v1/canarytoken/create_factory', params: params)['factory_auth']
      ThinkstCanary::Factory.new(factory_auth: factory_auth, **params)
    end

    private

    def configuration
      ThinkstCanary.configuration
    end
  end
end
