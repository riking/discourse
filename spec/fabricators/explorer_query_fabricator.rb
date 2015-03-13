Fabricator(:explorer_query) do
  name { sequence(:name) {|i| "Query_#{i}" } }
  description { sequence(:desc) {|i| "Query #{i} description"} }
  query "SELECT 1 AS value"
  creator { Fabricate(:admin) }
end
