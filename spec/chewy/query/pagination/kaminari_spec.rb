require 'hs_chewy/search/pagination/kaminari_examples'

describe HSChewy::Search::Pagination::Kaminari do
  it_behaves_like :kaminari, HSChewy::Query
end
