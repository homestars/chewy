require 'hs_chewy/search/parameters/integer_storage_examples'

describe HSChewy::Search::Parameters::TerminateAfter do
  it_behaves_like :integer_storage, :terminate_after
end
