require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # Just a standard string value storage, nothing to see here.
      #
      # @see Chewy::Search::Parameters::StringStorage
      # @see Chewy::Search::Request#search_type
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-search-type.html
      class SearchType < Storage
        include StringStorage
      end
    end
  end
end