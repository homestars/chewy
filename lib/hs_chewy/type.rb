require 'hs_chewy/search'
require 'hs_chewy/type/adapter/object'
require 'hs_chewy/type/adapter/active_record'
require 'hs_chewy/type/adapter/mongoid'
require 'hs_chewy/type/adapter/sequel'
require 'hs_chewy/type/mapping'
require 'hs_chewy/type/wrapper'
require 'hs_chewy/type/observe'
require 'hs_chewy/type/actions'
require 'hs_chewy/type/syncer'
require 'hs_chewy/type/crutch'
require 'hs_chewy/type/import'
require 'hs_chewy/type/witchcraft'

module HSChewy
  class Type
    IMPORT_OPTIONS_KEYS = %i[batch_size bulk_size refresh consistency replication raw_import journal pipeline].freeze

    include Search
    include Mapping
    include Wrapper
    include Observe
    include Actions
    include Crutch
    include Witchcraft
    include Import

    singleton_class.delegate :index_name, :derivable_index_name, :client, to: :index

    class_attribute :_default_import_options
    self._default_import_options = {}

    class << self
      # Chewy index current type belongs to. Defined inside `Chewy.create_type`
      #
      def index
        raise NotImplementedError, 'Looks like this type was defined outside the index scope and `.index` method is undefined for it'
      end

      # Current type adapter. Defined inside `Chewy.create_type`, derived from
      # `HSChewy::Index.define_type` arguments.
      #
      def adapter
        raise NotImplementedError
      end

      # Returns type name string
      #
      def type_name
        adapter.type_name
      end

      # Appends type name to {HSChewy::Index.derivable_name}
      #
      # @example
      #   class Namespace::UsersIndex < HSChewy::Index
      #     define_type User
      #   end
      #   UsersIndex::User.derivable_name # => 'namespace/users#user'
      #
      # @see HSChewy::Index.derivable_name
      # @return [String, nil] derivable name or nil when it is impossible to calculate
      def derivable_name
        @derivable_name ||= [index.derivable_name, type_name].join('#') if index && index.derivable_name
      end

      # This method is an API shared with {HSChewy::Index}, added for convenience.
      #
      # @return [HSChewy::Type] array containing itself
      def types
        [self]
      end

      # Returns list of public class methods defined in current type
      #
      def scopes
        public_methods - HSChewy::Type.public_methods
      end

      def default_import_options(params)
        params.assert_valid_keys(IMPORT_OPTIONS_KEYS)
        self._default_import_options = _default_import_options.merge(params)
      end

      def method_missing(method, *args, &block)
        if index.scopes.include?(method)
          define_singleton_method method do |*method_args, &method_block|
            all.scoping { index.public_send(method, *method_args, &method_block) }
          end
          send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, _)
        index.scopes.include?(method) || super
      end

      def const_missing(name)
        to_resolve = "#{self}::#{name}"
        to_resolve[index.to_s] = ''

        @__resolved_constants ||= {}

        if to_resolve.empty? || @__resolved_constants[to_resolve]
          super
        else
          @__resolved_constants[to_resolve] = true
          to_resolve.constantize
        end
      rescue NotImplementedError
        super
      end
    end
  end
end
