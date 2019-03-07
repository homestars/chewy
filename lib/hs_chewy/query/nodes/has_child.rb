require 'hs_chewy/query/nodes/has_relation'

module HSChewy
  class Query
    module Nodes
      class HasChild < HasRelation
      private

        def _relation
          :has_child
        end
      end
    end
  end
end
