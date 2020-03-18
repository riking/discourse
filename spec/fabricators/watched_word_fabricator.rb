# frozen_string_literal: true

Fabricator(:watched_word) do
  word { sequence(:word) { |i| "word#{i}" } }
  action { WatchedWord.actions[:block] }
  mode { WatchedWord.modes[:glob] }
  word_boundary { true }
end

Fabricator(:watched_word_regexp, from: :watched_word) do
  word { sequence(:word) { |i| "[qz]-#{i}" } }
  mode { WatchedWord.modes[:regexp] }
end

Fabricator(:watched_word_literal, from: :watched_word) do
  word { sequence(:word) { |i| ".*#{i}*." } }
  mode { WatchedWord.modes[:literal] }
end
