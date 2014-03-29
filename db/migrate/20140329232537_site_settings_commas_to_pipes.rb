class SiteSettingsCommasToPipes < ActiveRecord::Migration
  def up
    settings.each do |name|
      setting = SiteSetting.where(name: name).first
      unless setting.nil?
        setting.value = setting.value.sub ',', '|'
        setting.save
      end
    end
  end

  def down
    settings.each do |name|
      setting = SiteSetting.where(name: name).first
      unless setting.nil?
        setting.value = setting.value.sub '|', ','
        setting.save
      end
    end
  end

  def settings
    %w( exclude_rel_nofollow_domains
        white_listed_spam_host_domains
    )
  end
end
