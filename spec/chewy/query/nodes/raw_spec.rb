require 'spec_helper'

describe HSChewy::Query::Nodes::Raw do
  describe '#__render__' do
    def render(&block)
      HSChewy::Query::Filters.new(&block).__render__
    end

    specify { expect(render { r(term: {name: 'name'}) }).to eq(term: {name: 'name'}) }
  end
end
