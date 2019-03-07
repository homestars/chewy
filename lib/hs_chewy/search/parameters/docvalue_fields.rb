require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # @see HSChewy::Search::Parameters::StringArrayStorage
      class DocvalueFields < Storage
        include StringArrayStorage
      end
    end
  end
end
