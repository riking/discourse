class UserBadgesController < ApplicationController
  def index
    params.require(:username)
    user = fetch_user_from_params
    render_serialized(user.user_badges, UserBadgeSerializer, root: "user_badges")
  end

  def create
    params.require(:username)
    user = fetch_user_from_params

    unless can_assign_badge_to_user?(user)
      raise Discourse::InvalidAccess.new
    end

    badge = fetch_badge_from_params
    user_badge = BadgeGranter.grant(badge, user, granted_by: current_user)

    render_serialized(user_badge, UserBadgeSerializer, root: "user_badge")
  end

  def destroy
    params.require(:id)
    user_badge = UserBadge.find(params[:id])

    unless can_assign_badge_to_user?(user_badge.user)
      raise Discourse::InvalidAccess.new
    end

    BadgeGranter.revoke(user_badge, revoked_by: current_user)
    render json: success_json
  end

  private

    # Get the badge from either the badge name or id specified in the params.
    def fetch_badge_from_params
      badge = nil

      params.permit(:badge_name)
      if params[:badge_name].nil?
        params.require(:badge_id)
        badge = Badge.where(id: params[:badge_id]).first
      else
        badge = Badge.where(name: params[:badge_name]).first
      end
      raise Discourse::NotFound.new if badge.blank?

      badge
    end

    def can_assign_badge_to_user?(user)
      master_api_call = current_user.nil? && is_api?
      master_api_call or guardian.can_grant_badges?(user)
    end
end
