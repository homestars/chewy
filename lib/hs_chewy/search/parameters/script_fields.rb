require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # Just a standard hash storage. Nothing to see here.
      #
      # @see HSChewy::Search::Parameters::HashStorage
      # @see HSChewy::Search::Request#script_fields
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-script-fields.html
      class ScriptFields < Storage
        include HashStorage
      end
    end
  end
end
