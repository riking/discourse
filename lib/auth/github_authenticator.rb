class Auth::GithubAuthenticator < Auth::Authenticator

  def name
    "github"
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    data = auth_token[:info]

    result.username = screen_name = data["nickname"]

    # Get list of emails on account
    gh_token = auth_token[:credentials][:token]
    emails_response = MultiJson.load(
        RestClient.get('https://api.github.com/user/emails', params: {access_token: gh_token}, accept: :json)
    )
    # Remove unverified emails
    emails_response.reject {|x| !x['verified'] }
    # Select the primary email
    # TODO allow multiple returns?
    primary_email = emails_response.find { |x| x['primary'] }

    if primary_email
      result.email = primary_email['email']
      result.email_valid = primary_email['verified']
    else
      result.email = nil
      result.email_valid = false
    end

    github_user_id = auth_token["uid"]

    result.extra_data = {
      github_user_id: github_user_id,
      github_screen_name: screen_name,
    }

    user_info = GithubUserInfo.find_by(github_user_id: github_user_id)

    if user_info
      user = user_info.user
    # SECURITY: Do not perform user lookup for unverified emails
    # TODO: look up by all verified emails?
    elsif result.email_valid && user = User.find_by_email(email)
      user_info = GithubUserInfo.create(
          user_id: user.id,
          screen_name: screen_name,
          github_user_id: github_user_id
      )
    else
      user = nil
    end

    result.user = user

    result
  end

  def after_create_account(user, auth)
    data = auth[:extra_data]
    GithubUserInfo.create(
      user_id: user.id,
      screen_name: data[:github_screen_name],
      github_user_id: data[:github_user_id]
    )
  end


  def register_middleware(omniauth)
    omniauth.provider :github,
           :setup => lambda { |env|
              strategy = env["omniauth.strategy"]
              strategy.options[:client_id] = SiteSetting.github_client_id
              strategy.options[:client_secret] = SiteSetting.github_client_secret
           },
           :scope => "user:email"
  end
end
