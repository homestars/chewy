require 'hs_chewy/search/parameters/bool_storage_examples'

describe HSChewy::Search::Parameters::None do
  it_behaves_like :bool_storage, query: {bool: {filter: {bool: {must_not: {match_all: {}}}}}}
end
