require 'hs_chewy/query/nodes/has_relation'

module HSChewy
  class Query
    module Nodes
      class HasParent < HasRelation
      private

        def _relation
          :has_parent
        end
      end
    end
  end
end
