require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # A standard string array storage with one exception: rendering is empty.
      #
      # @see HSChewy::Search::Parameters::StringArrayStorage
      class Types < Storage
        include StringArrayStorage

        # Doesn't render anything, has specialized rendering logic in
        # {HSChewy::Search::Request}
        #
        # @return [nil]
        def render; end
      end
    end
  end
end
