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

end
