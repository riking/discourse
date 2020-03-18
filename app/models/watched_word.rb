# frozen_string_literal: true

class WatchedWord < ActiveRecord::Base

  def self.actions
    @actions ||= Enum.new(
      block: 1,
      censor: 2,
      require_approval: 3,
      flag: 4,
      link: 5,
    )
  end

  def self.modes
    @modes ||= Enum.new(
      glob: 1,
      literal: 2,
      regex: 3
    )
  end

  MAX_WORDS_PER_ACTION = 1000

  before_validation do
    self.word = self.class.normalize_word(self.word, self.mode)
  end

  validates :word,   presence: true, uniqueness: true, length: { maximum: 50 }
  validates :action, presence: true
  validates_each :word do |record, attr, val|
    if WatchedWord.where(action: record.action).count >= MAX_WORDS_PER_ACTION
      record.errors.add(:word, :too_many)
    end
    if record.mode == WatchedWord.modes[:regex]
      begin
        Regexp.new(val)
      rescue RegexpError
        record.errors.add(:word, :bad_regexp)
      end
      if val.include?('(?<')
        # Lookbehind is not supported by major browsers except Chrome.
        # Prevent its use to avoid mistakes.
        record.errors.add(:word, :no_lookbehind)
      end
    end
  end

  after_save    :clear_cache
  after_destroy :clear_cache

  scope :by_action, -> { order("action ASC, word ASC") }

  def self.normalize_word(w, mode)
    if mode == WatchedWord.modes[:glob]
      w.strip.squeeze('*')
    elsif mode == WatchedWord.modes[:literal]
      w.strip
    elsif mode == WatchedWord.modes[:regex]
      w.start_with?("(?-mix:") ? w[7..-2] : w
    end
  end

  def self.create_or_update_word(params)
    new_word = normalize_word(params[:word])
    w = WatchedWord.where("word ILIKE ?", new_word).first || WatchedWord.new(word: new_word)
    w.action_key = params[:action_key] if params[:action_key]
    w.action = params[:action] if params[:action]
    w.mode_key = params[:mode_key] if params[:mode_key]
    w.mode = params[:mode] if params[:mode]
    w.replacement = params[:replacement]
    w.save
    w
  end

  def action_key=(arg)
    self.action = self.class.actions[arg.to_sym]
  end

  def mode_key=(arg)
    self.mode = self.class.modes[arg.to_sym]
  end

  def regexp
    case self.mode
    when WatchedWord.modes[:literal]
      Regexp.escape(word)
    when WatchedWord.modes[:regex]
      word
    when WatchedWord.modes[:glob]
      self.word.split('').map { |char|
        case char
        when '?'
          '.'
        when '*'
          '\S*'
        else
          Regexp.escape(char)
        end
      }.join('')
    else
      WordWatcher.never_matching
    end
  end

  def clear_cache
    WordWatcher.clear_cache!
  end

end

# == Schema Information
#
# Table name: watched_words
#
#  id            :integer          not null, primary key
#  word          :string           not null
#  action        :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  mode          :integer          default("1")
#  word_boundary :boolean          default("true")
#  replacement   :text
#
# Indexes
#
#  index_watched_words_on_action_and_word  (action,word) UNIQUE
#
