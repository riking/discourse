require 'spec_helper'

describe ExplorerController do
  let(:admin) { Fabricate(:admin) }
  let(:moderator) { Fabricate(:moderator) }
  let(:user) { Fabricate(:user) }

  def site_settings(enable, public)
    SiteSetting.enable_data_explorer = enable
    SiteSetting.public_data_explorer = public
  end
  def settings_reset
    site_settings true, true
  end

  before do
    settings_reset
  end

  context 'permissions matrix' do
    let(:query_t_t) { Fabricate(:explorer_query, public_view: true, public_run: true) }
    let(:query_f_t) { Fabricate(:explorer_query, public_view: false, public_run: true) }
    let(:query_t_f) { Fabricate(:explorer_query, public_view: true, public_run: false) }
    let(:query_f_f) { Fabricate(:explorer_query, public_view: false, public_run: false) }
    let(:query_deleted) { Fabricate(:explorer_query, public_view: true, public_run: true, deleted_at: Time.now) }
    before do
      ExplorerQuery.delete_all

      query_t_t
      query_f_t
      query_t_f
      query_f_f
      query_deleted
    end

    describe 'index' do
      context "as admin" do
        before do
          log_in(:admin)
        end
        it "lists non-deleted queries" do
          site_settings true, true
          xhr :get, :index
          expect(response).to be_success
          expect(response_json).to be_is_a Array
          expect(response_json.length).to eq(4)
          settings_reset
        end
        it "is allowed when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          expect(response).to be_success
          settings_reset
        end
        it "is 404 when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          expect(response).to be_not_found
          settings_reset
        end
      end

      context "as moderator" do
        before do
          log_in(:moderator)
        end
        it "lists public queries" do
          site_settings true, true
          xhr :get, :index
          expect(response).to be_success
          expect(response_json).to be_is_a Array
          expect(response_json.length).to eq(3)
          settings_reset
        end
        it "is forbidden when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          expect(response).to be_forbidden
          settings_reset
        end
        it "is forbidden when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          expect(response).to be_forbidden
          settings_reset
        end
      end

      context "as normal user" do
        before do
          log_in(:moderator)
        end
        it "lists public queries" do
          site_settings true, true
          xhr :get, :index
          expect(response).to be_success
          expect(response_json).to be_is_a Array
          expect(response_json.length).to eq(3)
          settings_reset
        end
        it "is forbidden when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          expect(response).to be_forbidden
          settings_reset
        end
        it "is forbidden when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          expect(response).to be_forbidden
          settings_reset
        end
      end
    end


    describe 'show' do
      context "as admin" do
        before do
          log_in(:admin)
        end

        it "shows a public query" do
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_success
        end
        it "shows an admin-only query" do
          xhr :get, :show, { id: query_f_f.id }
          expect(response).to be_success
        end
        it "shows a deleted query" do
          xhr :get, :show, { id: query_deleted.id }
          expect(response).to be_success
        end
        it "is visible when data explorer is not public" do
          site_settings true, false
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_success
          settings_reset
        end
        it "is 404 when data explorer is disabled" do
          site_settings false, false
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_not_found
          settings_reset
        end
      end

      context "as normal user" do
        before do
          log_in(:user)
        end

        it "shows a public query" do
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_success
        end
        it "does not show an admin-only query" do
          xhr :get, :show, { id: query_f_f.id }
          expect(response).to be_forbidden
        end
        it "does not show a deleted query" do
          xhr :get, :show, { id: query_deleted.id }
          expect(response).to be_forbidden
        end
        it "is forbidden when data explorer is not public" do
          site_settings true, false
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_forbidden
          settings_reset
        end
        it "is forbidden when data explorer is disabled" do
          site_settings true, false
          xhr :get, :show, { id: query_f_t.id }
          expect(response).to be_forbidden
          settings_reset
        end
      end

      context "public_view" do
        it "keeps the query results" do
          query_t_t.query = "SELECT 1 AS value"

          xhr :post, :run, {
                explorer_id: query_t_t.id,
                explain: false
                   }
          expect(response).to be_success

          xhr :get, :show, { id: query_t_t.id }
          expect(response_json["explorer_query"]["last_result"]["rows"].first["value"]).to eq('1')
        end

        it "removes the query results when public_view is turned off" do
          query = Fabricate(:explorer_query)
          query.query = "SELECT :param AS value"
          qp = ExplorerQueryParameter.new(name: 'param')
          query.params = [qp]
          query.public_view = true
          query.public_run = true
          query.save

          xhr :post, :run, {
                     explorer_id: query.id,
                     explain: false,
                     params: { param: 2 }
                   }
          expect(response_json["rows"].first["value"]).to eq('2')

          xhr :get, :show, { id: query.id }
          expect(response_json["explorer_query"]["last_result"]["rows"].first["value"]).to eq('2')

          query.public_view = false
          query.save

          xhr :get, :show, { id: query.id }
          expect(response_json["explorer_query"]["last_result"]).to be_nil
        end
      end
    end
  end

  describe "prevents modification of the database" do
    let(:equery) { Fabricate(:explorer_query) }
    let(:victim) { Fabricate(:post, cooked: '<p>Not modified Not modified Not modified</p>') }
    let(:victim_id) { victim.id }
    let(:target_id) { -2 }

    before do
      log_in(:admin)
    end

    def run(sql, explain=true)
      equery.query = sql
      equery.save
      xhr :post, :run, {
            explorer_id: equery.id,
            params: { limit: '10' },
            explain: explain ? 'true' : 'false'
               }
      expect(response).to_not be_success
      verify
      response_json
    end

    def verify
      p = Post.where(id: victim_id).first
      raise "FAIL: VICTIM WAS DELETED" unless p.present?
      if p.cooked =~ /winner/
        raise "FAIL: VICTIM HAD POST CHANGED"
      end
    end

    it "cannot execute an UPDATE" do
      query = <<SQL
UPDATE posts SET cooked = '<big>winner</big>' WHERE id = #{victim_id} RETURNING id
SQL
      expect((run query)["errors"].first).to match /read-only/
    end

    it "cannot execute a DELETE" do
      query = <<SQL
DELETE FROM posts WHERE id = #{victim_id} RETURNING id
SQL
      expect((run query)["errors"].first).to match /read-only/
    end

    it "cannot drop a table" do
      query = <<SQL
DROP TABLE posts
SQL
      expect((run query)["errors"].first).to match /syntax error/
    end

    it "cannot create an index" do
      query = <<SQL
CREATE INDEX foo ON posts (id, cooked)
SQL
      expect((run query)["errors"].first).to match /syntax error/
    end

    it "cannot lock rows" do
      query = <<SQL
SELECT * FROM posts FOR UPDATE
SQL
      expect((run query)["errors"].first).to match /read-only/
    end

    it "cannot commit the transaction and begin a new one" do
      query = <<SQL
SELECT 1 AS value;
COMMIT;
BEGIN TRANSACTION;
UPDATE posts SET cooked = '<big>winner</big>' WHERE id = #{victim_id};
COMMIT;
BEGIN TRANSACTION;
SQL

      expect((run query)["errors"].first).to match /multiple statements/
    end
  end

  describe "integration test" do
    before do
      site_settings true, true
    end

    it "creates, runs a query on the database" do
      admin = log_in(:admin)

      # Create a query
      xhr :post, :create, {name: "Integration Test Query"}
      expect(response).to be_success
      id = response_json["explorer_query"]["id"]
      expect(id).to_not be_nil

      # It shows up in the list
      xhr :get, :index
      expect(response).to be_success
      response_json.select { |q| q["id"] == id }.should be_present

      # View it
      xhr :get, :show, {id: id}
      expect(response).to be_success
      response_json["explorer_query"].should be_is_a Hash
      response_json["explorer_query"]["creator"]["id"].should eq(admin.id)

      # Input a query
      xhr :put, :update, {
            id: id,
            name: "Integration Test Query",
            query: "
SELECT
ub.badge_id badge$,
ub.user_id user$,
ub.post_id post$,
p.topic_id topic$,
t.category_id category$,
ub.granted_at reltime$granted_at,
ub.granted_by_id user$granted_by,
1 one
FROM user_badges ub
INNER JOIN posts p ON ub.post_id = p.id
INNER JOIN topics t ON p.topic_id = t.id
WHERE ub.user_id = :user_id
ORDER BY ub.id DESC -- Take the most recent grant only
LIMIT :limitB",
            description: "unícöde in thé des©ripti😃n",
            params: {
              '0' => {
                name: 'limitB',
                default_value: '',
                type: 'integer'
              },
              '1' => {
                name: 'user_id',
                default_value: '$current_user_id',
                type: 'integer',
                public_edit: 'false'
              }
            },
            params_empty: false,
            public_view: false,
            public_run: true
               }
      expect(response).to be_success
      eqjson = response_json["explorer_query"]
      eqjson.should be_is_a Hash
      eqjson["public_run"].should eq(true)
      eqjson["params"].first["name"].should eq('limitB')
      eqjson["params"].first["public_edit"].should eq(true)

      # It's saved in the database
      ExplorerQuery.find(id).params.first.name.should eq('limitB')

      # We can trash and recover it
      xhr :delete, :destroy, {id: id}
      expect(response).to be_success
      expect(ExplorerQuery.where(id: id)).to_not be_present
      expect(ExplorerQuery.with_deleted.find(id).deleted_by_id).to eq(admin.id)
      xhr :put, :recover, {explorer_id: id}
      expect(response).to be_success
      ExplorerQuery.where(id: id).should be_present
      ExplorerQuery.find(id).deleted_by_id.should be_nil

      # Create a badge for the query to find
      t = Fabricate(:topic)
      p = Fabricate(:post, topic: t)
      b = Fabricate(:badge)
      ub = BadgeGranter.grant(b, admin, granted_by: admin, post_id: p.id)

      # Run the query
      xhr :post, :run, {
            explorer_id: id,
            params: {
              limitB: '1',
              # user_id not specified, so it will be forced to use the default, THEN replace in $current_user_id
            },
            explain: true
               }

      # The response is correct
      expect(response).to be_success
      expect(response_json["success"]).to eq(true)
      expect(response_json["columns"]).to eq(['badge$', 'user$', 'post$', 'topic$', 'category$', 'reltime$granted_at', 'user$granted_by', 'one'])
      %w(badge user post topic category reltime).each do |relation|
        expect(response_json["relations"]).to include(relation)
      end
      expect(response_json["rows"].length).to eq(1)
      row = response_json["rows"].first
      expect(row["badge$"]).to eq(b.id.to_s)
      expect(row["user$"]).to eq(admin.id.to_s)
      expect(row["post$"]).to eq(p.id.to_s)
      expect(row["topic$"]).to eq(t.id.to_s)
      expect(Time.zone.parse(row["reltime$granted_at"]).to_i).to eq(ub.granted_at.to_i)
      expect(row["category$"]).to eq(t.category_id.to_s)
      expect(row["user$granted_by"]).to eq(admin.id.to_s)
      expect(row["one"]).to eq(1.to_s)
    end
  end

end
