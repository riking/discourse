
module AmpHelper

  def self.plugin_processors
    @plugin_processors ||= []
  end

  def self.register_plugin_style(&block)
    plugin_processors << block
  end

  def self.extended_components
    @extended_components ||= []
  end

  def self.register_extended_component(name, version)
    extended_components << [name, version]
  end

  def no_amp_url
    u = URI(request.url)
    u.query = nil
    u.to_s
  end

  # this is the logic of formatter.js relativeAgeMedium()
  def smart_time(timestamp)
    now = Time.zone.now
    distance = now - timestamp
    full = timestamp.strftime(I18n.t('date.formats.full_with_year'))

    abbreviated = if distance < 1.minute
        I18n.t('js.now')
      elsif distance > 5.days
        if now.year != timestamp.year
          timestamp.strftime(I18n.t('date.formats.date_only'))
        else
          timestamp.strftime(I18n.t('date.formats.short_no_year'))
        end
      elsif distance < 55.minutes
        I18n.t('js.dates.medium.x_minutes', count: (distance / 1.minute).round)
      elsif distance < 89.minutes
        I18n.t('js.dates.medium.x_hours', count: 1)
      elsif distance < 1409.minutes
        I18n.t('js.dates.medium.x_hours', count: (distance / 1.hour).round)
      elsif distance < 2159.minutes
        I18n.t('js.dates.medium.x_days', count: 1)
      else
        I18n.t('js.dates.medium.x_days', count: (distance / 1.day).round)
      end

    "<span class='date' title='#{h(full)}'>#{h(abbreviated)}</span>".html_safe
  end

  def amp_render_extended_components
    AmpHelper.extended_components.map do |n_v|
      name = n_v[0]
      version = n_v[1]
      "<script async custom-element='amp-#{name}' src='https://cdn.ampproject.org/v0/amp-#{name}-#{version}.js'></script>"
    end.join("\n").html_safe
  end

  def ampify_post(cooked)
    doc = Nokogiri::HTML.fragment(cooked)

    AmpHelper.plugin_processors.each do |block|
      block.call(doc)
    end

    doc.css('iframe').each do |iframe|
      src = iframe['src']
      if src.starts_with?('https://www.youtube.com/embed')
        match = src.match /https:\/\/www\.youtube\.com\/embed\/([-a-zA-Z0-9_)]+)/
        iframe.replace "<amp-youtube width=480 height=270 video-id=#{match[1]}></amp-youtube>"
      else
        iframe.name = 'amp-iframe'
        iframe.remove_attribute 'style'
        iframe.remove_attribute 'scrolling'
        iframe.remove_attribute 'marginheight'
        iframe.remove_attribute 'marginwidth'
        iframe['sandbox'] = 'allow-scripts'

        # https mandatory
        if src.starts_with?('//')
          iframe['src'] = "https:#{src}"
        elsif src.starts_with?('http:')
          iframe['src'] = src.gsub('http', 'https')
        end
      end
    end

    doc.css('img.emoji,img.avatar').each do |img|
      img.name = 'amp-img'
      img['width'] = '20'
      img['height'] = '20'
    end
    doc.css('img').each do |img|
      if img['width'].presence && img['height'].presence
        img.name = 'amp-img'
        img
      elsif img['src'].blank?
        img.replace ''
      else
        img.replace "<a href=#{img['src']}>#{img['alt'] || img['title'] || I18n.t(:excerpt_image)}</a>"
      end
    end
    doc.css("div[onclick=\"style.pointerEvents='none'\"]").remove
    doc.css("div[style='clear: both']").each {|n| n.replace '<div class="clearfix">' }

    doc.to_html.html_safe
  end
end

AmpHelper.register_extended_component :youtube, '0.1'
AmpHelper.register_extended_component :iframe, '0.1'
