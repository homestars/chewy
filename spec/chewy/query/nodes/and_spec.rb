require 'spec_helper'

describe HSChewy::Query::Nodes::And do
  describe '#__render__' do
    def render(&block)
      HSChewy::Query::Filters.new(&block).__render__
    end

    specify { expect(render { name? & (email == 'email') }).to eq(and: [{exists: {field: 'name'}}, {term: {'email' => 'email'}}]) }
    specify { expect(render { ~(name? & (email == 'email')) }).to eq(and: {filters: [{exists: {field: 'name'}}, {term: {'email' => 'email'}}], _cache: true}) }
  end
end
