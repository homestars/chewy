require 'active_support/version'
require 'active_support/concern'
require 'active_support/deprecation'
require 'active_support/json'
require 'active_support/log_subscriber'

require 'active_support/core_ext/array/access'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/string/inflections'

require 'i18n/core_ext/hash'
require 'hs_chewy/backports/deep_dup' unless Object.respond_to?(:deep_dup)
require 'singleton'
require 'base64'

require 'elasticsearch'

def try_require(path)
  require path
rescue LoadError
  nil
end

try_require 'kaminari'
try_require 'kaminari/core'
try_require 'will_paginate'
try_require 'will_paginate/collection'
try_require 'parallel'

ActiveSupport.on_load(:active_record) do
  try_require 'will_paginate/active_record'
  try_require 'kaminari/activerecord'
end

ActiveSupport.on_load(:mongoid) do
  try_require 'will_paginate/mongoid'
  try_require 'kaminari/mongoid'
end

require 'hs_chewy/version'
require 'hs_chewy/errors'
require 'hs_chewy/config'
require 'hs_chewy/rake_helper'
require 'hs_chewy/repository'
require 'hs_chewy/runtime'
require 'hs_chewy/log_subscriber'
require 'hs_chewy/strategy'
require 'hs_chewy/index'
require 'hs_chewy/type'
require 'hs_chewy/fields/base'
require 'hs_chewy/fields/root'
require 'hs_chewy/journal'
require 'hs_chewy/railtie' if defined?(::Rails::Railtie)

ActiveSupport.on_load(:active_record) do
  extend HSChewy::Type::Observe::ActiveRecordMethods
end

ActiveSupport.on_load(:mongoid) do
  module Mongoid
    module Document
      module ClassMethods
        include HSChewy::Type::Observe::MongoidMethods
      end
    end
  end
end

module HSChewy
  @adapters = [
    HSChewy::Type::Adapter::ActiveRecord,
    HSChewy::Type::Adapter::Mongoid,
    HSChewy::Type::Adapter::Sequel,
    HSChewy::Type::Adapter::Object
  ]

  class << self
    attr_accessor :adapters

    # Derives a single type for the passed string identifier if possible.
    #
    # @example
    #   HSChewy.derive_types(UsersIndex::User) # => UsersIndex::User
    #   HSChewy.derive_types('namespace/users') # => Namespace::UsersIndex::User
    #   HSChewy.derive_types('places') # => raises HSChewy::UnderivableType
    #   HSChewy.derive_types('places#city') # => PlacesIndex::City
    #
    # @param name [String, HSChewy::Type] string type identifier
    # @raise [HSChewy::UnderivableType] in cases when it is impossble to find index or type or more than one type found
    # @return [HSChewy::Type] an array of derived types
    def derive_type(name)
      return name if name.is_a?(Class) && name < HSChewy::Type

      types = derive_types(name)
      raise HSChewy::UnderivableType, "Index `#{types.first.index}` has more than one type, please specify type via `#{types.first.index.derivable_name}#type_name`" unless types.one?
      types.first
    end

    # Derives all the types for the passed string identifier if possible.
    #
    # @example
    #   HSChewy.derive_types('namespace/users') # => [Namespace::UsersIndex::User]
    #   HSChewy.derive_types('places') # => [PlacesIndex::City, PlacesIndex::Country]
    #   HSChewy.derive_types('places#city') # => [PlacesIndex::City]
    #
    # @param from [String] string type identifier
    # @raise [HSChewy::UnderivableType] in cases when it is impossible to find index or type
    # @return [Array<HSChewy::Type>] an array of derived types
    def derive_types(from)
      return from.types if from.is_a?(Class) && (from < HSChewy::Index || from < HSChewy::Type)

      index_name, type_name = from.split('#', 2)
      class_name = "#{index_name.camelize.gsub(/Index\z/, '')}Index"
      index = class_name.safe_constantize
      raise HSChewy::UnderivableType, "Can not find index named `#{class_name}`" unless index && index < HSChewy::Index
      if type_name.present?
        type = index.type_hash[type_name] or raise HSChewy::UnderivableType, "Index `#{class_name}` doesn`t have type named `#{type_name}`"
        [type]
      else
        index.types
      end
    end

    # Creates HSChewy::Type ancestor defining index and adapter methods.
    #
    def create_type(index, target, options = {}, &block)
      type = Class.new(HSChewy::Type)

      adapter = adapters.find { |klass| klass.accepts?(target) }.new(target, options)

      index.const_set(adapter.name, type)
      type.send(:define_singleton_method, :index) { index }
      type.send(:define_singleton_method, :adapter) { adapter }

      type.class_eval(&block) if block
      type
    end

    # Main elasticsearch-ruby client instance
    #
    def client
      Thread.current[:chewy_client] ||= begin
        client_configuration = configuration.deep_dup
        client_configuration.delete(:prefix) # used by Chewy, not relevant to Elasticsearch::Client
        block = client_configuration[:transport_options].try(:delete, :proc)
        ::Elasticsearch::Client.new(client_configuration, &block)
      end
    end

    # Sends wait_for_status request to ElasticSearch with status
    # defined in configuration.
    #
    # Does nothing in case of config `wait_for_status` is undefined.
    #
    def wait_for_status
      client.cluster.health wait_for_status: HSChewy.configuration[:wait_for_status] if HSChewy.configuration[:wait_for_status].present?
    end

    # Deletes all corresponding indexes with current prefix from ElasticSearch.
    # Be careful, if current prefix is blank, this will destroy all the indexes.
    #
    def massacre
      HSChewy.client.indices.delete(index: [HSChewy.configuration[:prefix], '*'].reject(&:blank?).join('_'))
      HSChewy.wait_for_status
    end
    alias_method :delete_all, :massacre

    # Strategies are designed to allow nesting, so it is possible
    # to redefine it for nested contexts.
    #
    #   HSChewy.strategy(:atomic) do
    #     city1.do_update!
    #     HSChewy.strategy(:urgent) do
    #       city2.do_update!
    #       city3.do_update!
    #       # there will be 2 update index requests for city2 and city3
    #     end
    #     city4..do_update!
    #     # city1 and city4 will be grouped in one index update request
    #   end
    #
    # It is possible to nest strategies without blocks:
    #
    #   HSChewy.strategy(:urgent)
    #   city1.do_update! # index updated
    #   HSChewy.strategy(:bypass)
    #   city2.do_update! # update bypassed
    #   HSChewy.strategy.pop
    #   city3.do_update! # index updated again
    #
    def strategy(name = nil, &block)
      Thread.current[:chewy_strategy] ||= HSChewy::Strategy.new
      if name
        if block
          Thread.current[:chewy_strategy].wrap name, &block
        else
          Thread.current[:chewy_strategy].push name
        end
      else
        Thread.current[:chewy_strategy]
      end
    end

    def config
      HSChewy::Config.instance
    end
    delegate(*HSChewy::Config.delegated, to: :config)

    def repository
      HSChewy::Repository.instance
    end
    delegate(*HSChewy::Repository.delegated, to: :repository)

    def create_indices
      HSChewy::Index.descendants.each(&:create)
    end

    def create_indices!
      HSChewy::Index.descendants.each(&:create!)
    end

    def eager_load!
      return unless defined?(HSChewy::Railtie)
      dirs = HSChewy::Railtie.all_engines.map { |engine| engine.paths[HSChewy.configuration[:indices_path]] }.compact.map(&:existent).flatten.uniq

      dirs.each do |dir|
        Dir.glob(File.join(dir, '**/*.rb')).each do |file|
          require_dependency file
        end
      end
    end
  end
end

require 'hs_chewy/stash'
