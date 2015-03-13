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
    before do
      ExplorerQuery.delete_all

      Fabricate(:explorer_query, public_view: true, public_run: true)
      Fabricate(:explorer_query, public_view: false, public_run: true)
      Fabricate(:explorer_query, public_view: true, public_run: false)
      Fabricate(:explorer_query, public_view: false, public_run: false)

      Fabricate(:explorer_query, public_view: true, public_run: true, deleted_at: Time.now)
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


    context 'show' do

    end
  end

  describe "prevents modification" do
    let(:equery) { Fabricate(:explorer_query) }
    let(:victim) { Fabricate(:post, user_id: -1) }
    let(:victim_id) { victim.id }
    let(:target_id) { -2 }

    before do
      log_in(:admin)
    end

    after do
      ActiveRecord::Base.exec_sql("ROLLBACK")
    end

    def run(sql, explain=true)
      equery.query = sql
      equery.save
      xhr :post, :run, {
            explorer_id: equery.id,
            params: { limit: '10' },
            explain: explain ? 'true' : 'false'
               }
      puts response_json["errors"]
      verify
    end

    def verify
      p = Post.where(id: victim_id).first
      raise "FAIL: VICTIM WAS DELETED" unless p.present?
      if p.cooked =~ /winner/
        raise "FAIL: VICTIM HAD POST CHANGED"
      end
    end

    it "cannot execute an UPDATE" do

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

      run query
    end
  end

  describe "integration test" do
    before do
      site_settings true, true
    end

    it "creates, runs a query on the database" do
      log_in(:admin)

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
ub.granted_at reltime$granted_at,
ub.granted_by_id user$granted_by
FROM user_badges ub
INNER JOIN posts p ON ub.post_id = p.id
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
      puts response_json
      expect(response).to be_success
      expect(response_json["success"]).to eq(true)

      binding.pry
    end
  end

end
