require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # Just a standard string value storage, nothing to see here.
      #
      # @see HSChewy::Search::Parameters::StringStorage
      # @see HSChewy::Search::Request#preference
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-preference.html
      class Preference < Storage
        include StringStorage
      end
    end
  end
end
