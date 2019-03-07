require 'hs_chewy/search/parameters/storage'

module HSChewy
  module Search
    class Parameters
      # Just a simple value storage, all the values are coerced to float.
      class MinScore < Storage
      private

        def normalize(value)
          Float(value) if value
        end
      end
    end
  end
end
