require 'hs_chewy/search/parameters/bool_storage_examples'

describe HSChewy::Search::Parameters::Explain do
  it_behaves_like :bool_storage, :explain
end
