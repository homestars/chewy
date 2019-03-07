module HSChewy
  class Index
    # Index specification is a combination of index settings and
    # mappings. The idea behind this class is that specification
    # can be locked in the `HSChewy::Stash::Specification` between
    # resets, so it is possible to track changes. In the future
    # it is planned to be way smarter but right now `rake chewy:deploy`
    # checks if there were changes and resets the index only if
    # anything was changed. Otherwise, the index reset is skipped.
    #
    # @see HSChewy::Stash::Specification
    class Specification
      # @see HSChewy::Index::Specification
      # @param index [HSChewy::Index] Just a chewy index
      def initialize(index)
        @index = index
      end

      # Stores the current index specification to the `HSChewy::Stash::Specification`
      # as json.
      #
      # @raise [HSChewy::ImportFailed] if something went wrong
      # @return [true] if everything is fine
      def lock!
        HSChewy::Stash::Specification.import!([
          id: @index.derivable_name,
          specification: Base64.encode64(current.to_json)
        ], journal: false)
      end

      # Returns the last locked specification as ruby hash. Returns
      # empty hash if nothing is stored yet.
      #
      # @return [Hash] hash produced with JSON parser
      def locked
        filter = {ids: {values: [@index.derivable_name]}}
        document = HSChewy::Stash::Specification.filter(filter).first
        return {} unless document
        JSON.load(Base64.decode64(document.specification)) # rubocop:disable Security/JSONLoad
      end

      # Simply returns `HSChewy::Index.specification_hash`, but
      # prepared for JSON with `as_json` method. This means all the
      # keys are strings and there are only values of types handled in JSON.
      #
      # @see HSChewy::Index.specification_hash
      # @return [Hash] a JSON-ready hash
      def current
        @index.specification_hash.as_json
      end

      # Compares previously locked and current specifications.
      #
      # @return [true, false] the result of comparison
      def changed?
        current != locked
      end
    end
  end
end
