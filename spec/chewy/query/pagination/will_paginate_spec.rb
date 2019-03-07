require 'hs_chewy/search/pagination/will_paginate_examples'

describe HSChewy::Search::Pagination::WillPaginate do
  it_behaves_like :will_paginate, HSChewy::Query
end
