# frozen_string_literal: true

class AddMoreToWatchedWords < ActiveRecord::Migration[6.0]
  def change
    add_column :watched_words, :mode, :int, default: WatchedWord.mode[:glob]
    add_column :watched_words, :word_boundary, :boolean, default: true
    # note: multi-use column depending on the action
    add_column :watched_words, :replacement, :text, null: true

    reversible do |dir|
      dir.up do
        watched_word_regex = SiteSetting.find_by(name: "watched_words_regular_expressions")
        if watched_word_regex && (watched_word_regex.value == 't' || watched_word_regex.value == 'true')
          WatchedWord.update_all(mode: WatchedWord.mode[:regex])
        end
      end
      dir.down do
        # nothing
      end
    end
  end
end
