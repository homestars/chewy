module HSChewy
  class Type
    module Actions
      extend ActiveSupport::Concern

      module ClassMethods
        # Deletes all documents of a type and reimports them
        #
        # @example
        #   UsersIndex::User.reset
        #
        # @see HSChewy::Type::Import::ClassMethods#import
        # @see HSChewy::Type::Import::ClassMethods#import
        # @return [true, false] the result of import
        def reset
          delete_all
          import
        end

        # Performs missing and outdated objects synchronization for the current type.
        #
        # @example
        #   UsersIndex::User.sync
        #
        # @see HSChewy::Type::Syncer
        # @param parallel [true, Integer, Hash] options for parallel execution or the number of processes
        # @return [Hash{Symbol, Object}, nil] a number of missing and outdated documents reindexed and their ids, nil in case of errors
        def sync(parallel: nil)
          syncer = Syncer.new(self, parallel: parallel)
          count = syncer.perform
          {count: count, missing: syncer.missing_ids, outdated: syncer.outdated_ids} if count
        end

        # A {HSChewy::Journal} instance for the particular type
        #
        # @return [HSChewy::Journal] journal instance
        def journal
          @journal ||= HSChewy::Journal.new(self)
        end
      end
    end
  end
end
