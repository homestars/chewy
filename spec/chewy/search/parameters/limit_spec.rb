require 'hs_chewy/search/parameters/integer_storage_examples'

describe HSChewy::Search::Parameters::Limit do
  it_behaves_like :integer_storage, :size
end
