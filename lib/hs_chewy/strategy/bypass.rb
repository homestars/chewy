module HSChewy
  class Strategy
    # This strategy basically does nothing.
    #
    #   HSChewy.strategy(:bypass) do
    #     User.all.map(&:save) # Does nothing here
    #     # Does not update index all over the block.
    #   end
    #
    class Bypass < Base
      def update(type, objects, _options = {}); end
    end
  end
end
