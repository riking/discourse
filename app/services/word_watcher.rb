# frozen_string_literal: true

class WordWatcher

  def initialize(raw)
    @raw = raw
  end

  IDX_WORD = 0
  IDX_MODE = 1
  IDX_BOUND = 2

  def self.words_for_action(action)
    WatchedWord.where(action: WatchedWord.actions[action.to_sym]).limit(1000).pluck(:word, :mode, :word_boundary)
  end

  def self.words_for_action_exists?(action)
    WatchedWord.where(action: WatchedWord.actions[action.to_sym]).exists?
  end

  def self.never_matching
    '(?!)'
  end

  def self.get_cached_words(action)
    Discourse.cache.fetch(word_matcher_regexp_key(action), expires_in: 1.day) do
      words_for_action(action).presence
    end
  end

  # This regexp is run in miniracer, and the client JS app
  # Make sure it is compatible with major browsers when changing
  # hint: non-chrome browsers do not support 'lookbehind'
  def self.word_matcher_regexp(action, raise_errors: false)
    words = get_cached_words(action)

    if words
      with_boundary = words.filter { |w| w[IDX_BOUND] }.map { |w| self.cached_word_to_regexp(w) }.join('|')
      without_boundary = words.filter { |w| !w[IDX_BOUND] }.map { |w| self.cached_word_to_regexp(w) }.join('|')

      with_boundary_present = with_boundary.present?
      with_boundary = "(?:\\W|^)(#{with_boundary})(?=\\W|$)"
      if with_boundary_present && without_boundary.present?
        regexp = "(#{without_boundary})|#{with_boundary}"
      elsif with_boundary_present
        regexp = "#{with_boundary}"
      elsif without_boundary.present?
        regexp = "(#{without_boundary})"
      else
        regexp = WordWatcher.never_matching
      end

      Regexp.new(regexp, Regexp::IGNORECASE)
    end
  rescue RegexpError => e
    raise if raise_errors
    nil # Admin will be alerted via admin_dashboard_data.rb
  end

  def self.cached_word_to_regexp(cached_word)
    WatchedWord.word_to_regexp(cached_word[IDX_WORD], cached_word[IDX_MODE])
  end

  def self.word_matcher_regexp_key(action)
    "watched-words-list:#{action}"
  end

  def self.clear_cache!
    WatchedWord.actions.each do |a, i|
      Discourse.cache.delete word_matcher_regexp_key(a)
    end
  end

  def requires_approval?
    word_matches_for_action?(:require_approval)
  end

  def should_flag?
    word_matches_for_action?(:flag)
  end

  def should_block?
    word_matches_for_action?(:block, all_matches: true)
  end

  # note: do not rely on subscript indices of the returned value if !all_matches
  # use m.find(&:present?) instead
  def word_matches_for_action?(action, all_matches: false)
    regexp = self.class.word_matcher_regexp(action)
    if regexp
      match = regexp.match(@raw)
      return match if !all_matches || !match

      set = Set.new
      @raw.scan(regexp).each do |m|
        if Array === m
          # only use the first (widest) match
          set.add(m.find(&:present?))
        elsif String === m
          set.add(m)
        end
      end
      matches = set.to_a
      matches.compact!
      matches.sort!
      matches
    else
      false
    end
  end
end
