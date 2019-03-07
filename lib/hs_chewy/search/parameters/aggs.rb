require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # Just a standard hash storage. Nothing to see here.
      #
      # @see HSChewy::Search::Parameters::HashStorage
      # @see HSChewy::Search::Request#aggregations
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
      class Aggs < Storage
        include HashStorage
      end
    end
  end
end
