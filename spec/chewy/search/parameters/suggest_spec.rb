require 'hs_chewy/search/parameters/hash_storage_examples'

describe HSChewy::Search::Parameters::Suggest do
  it_behaves_like :hash_storage, :suggest
end
