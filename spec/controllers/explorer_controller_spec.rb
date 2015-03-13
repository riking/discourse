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
          response.should be_success
          json = MultiJson.load(response.body)
          json.should be_is_a Array
          json.length.should eq(4)
          settings_reset
        end
        it "is allowed when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          response.should_not be_forbidden
          settings_reset
        end
        it "is 404 when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          response.status.should eq(404)
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
          response.should be_success
          json = MultiJson.load(response.body)
          json.should be_is_a Array
          json.length.should eq(3)
          settings_reset
        end
        it "is forbidden when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          response.should be_forbidden
          settings_reset
        end
        it "is forbidden when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          response.should be_forbidden
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
          response.should be_success
          json = MultiJson.load(response.body)
          json.should be_is_a Array
          json.length.should eq(3)
          settings_reset
        end
        it "is forbidden when data explorer is not public" do
          site_settings true, false
          xhr :get, :index
          response.should be_forbidden
          settings_reset
        end
        it "is forbidden when data explorer is disabled" do
          site_settings false, false
          xhr :get, :index
          response.should be_forbidden
          settings_reset
        end
      end
    end


    context 'show' do

    end
  end

  describe "integration test" do
    before do
      site_settings true, true
      log_in(:admin)
      it "creates, runs a query on the database" do

        # Create a query
        xhr :post, :create, {name: "Integration Test Query"}
        response.should be_success
        json = MultiJson.load(response.body)
        id = json[:explorer_query][:id]
        id.should_not be_nil

        # It shows up in the list
        xhr :get, :index
        response.should be_success
        json = MultiJson.load(response.body)
        json.select { |q| q[:id] == id }.should be_present

        # View it
        xhr :get, :show, {id: id}
        response.should be_success
        json = MultiJson.load(response.body)
        json[:explorer_query].should be_is_a Hash
        json[:explorer_query][:creator][:id].should eq(current_user.id)

        # Input a query
        xhr :post, :update, {
              name: "Integration Test Query",
              query: "
SELECT
  ub.badge_id badge$,
  ub.post_id post$,
  ub.user_id user$,
  p.topic_id topic$,
  ub.granted_at reltime$granted_at
FROM user_badges ub
INNER JOIN posts p ON ub.post_id = p.id
WHERE ub.user_id = :user_id
LIMIT :limit",
              description: "unícöde in thé des©ripti😃n",
              params: [
                {
                  name: 'limitB',
                  default_value: '',
                  type: 'integer'
                },
                {
                  name: 'user_id',
                  default_value: '$current_user_id',
                  type: 'integer',
                  public_edit: 'false'
                }
              ],
              params_empty: false,
              public_view: false,
              public_run: true
                 }
        response.should be_success
        json = MultiJson.load(response.body)
        json[:explorer_query].should be_is_a Hash
        json[:explorer_query][:public_run].should eq(true)
        json[:explorer_query][:params].first[:name].should eq('limitB')
        json[:explorer_query][:params].first[:public_edit].should eq(true)
        # It's saved in the database
        ExplorerQuery.find(id).params.first.name.should eq('limitB')

        # We can trash and recover it
        xhr :delete, :destroy, {id: id}
        ExplorerQuery.where(id: id).should_not be_present
        ExplorerQuery.with_deleted.find(id).deleted_by_id.should eq(current_user.id)
        xhr :put, :recover, {id: id}
        ExplorerQuery.where(id: id).should be_present
        ExplorerQuery.find(id).deleted_by_id.should be_nil


      end
    end
  end

end
