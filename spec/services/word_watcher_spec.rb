# frozen_string_literal: true

require 'rails_helper'

describe WordWatcher do

  let(:raw) { "Do you like liquorice?\n\nI really like them. One could even say that I am *addicted* to liquorice. Anf if\nyou can mix it up with some anise, then I'm in heaven ;)" }

  after do
    Discourse.redis.flushall
  end

  describe '.word_matcher_regexp' do
    let!(:word1) { Fabricate(:watched_word, action: WatchedWord.actions[:block]) }
    let!(:word2) { Fabricate(:watched_word, word: 'a.aa*b?b', action: WatchedWord.actions[:block], word_boundary: false) }
    let!(:word3) { Fabricate(:watched_word_regexp, action: WatchedWord.actions[:block]) }
    let!(:word4) { Fabricate(:watched_word_literal, action: WatchedWord.actions[:block], word_boundary: false) }

    context 'per word regexp generation' do
      it "is correct for plain examples" do
        expect(word1.regexp).to eq(word1.word)
      end

      it "is correct for complex globs" do
        expect(word2.regexp).to eq('a\.aa\S*b.b')
      end

      it "is correct for regexp" do
        expect(word3.regexp).to eq(word3.word)
      end

      it "is correct for literals" do
        expect(word4.regexp).to eq(Regexp.escape(word4.word))
      end
    end

    context 'format of the result regexp' do
      it "correctly adds the word boundary where expected" do
        regexp = WordWatcher.word_matcher_regexp(:block)
        # word2, word4 have no word boundary
        expect(regexp.inspect).to eq("/(#{word2.regexp}|#{word4.regexp})|(?:\\W|^)(#{word1.regexp}|#{word3.regexp})(?=\\W|$)/i")
      end
    end
  end

  describe "word_matches_for_action?" do
    it "is falsey when there are no watched words" do
      expect(WordWatcher.new(raw).word_matches_for_action?(:require_approval)).to be_falsey
    end

    context "with watched words" do
      fab!(:anise) { Fabricate(:watched_word, word: "anise", action: WatchedWord.actions[:require_approval]) }

      it "is falsey without a match" do
        expect(WordWatcher.new("No liquorice for me, thanks...").word_matches_for_action?(:require_approval)).to be_falsey
      end

      it "is returns matched words if there's a match" do
        m = WordWatcher.new(raw).word_matches_for_action?(:require_approval)
        expect(m).to be_truthy
        expect(m[1]).to eq(anise.word)
      end

      it "finds at start of string" do
        m = WordWatcher.new("#{anise.word} is garbage").word_matches_for_action?(:require_approval)
        expect(m[1]).to eq(anise.word)
      end

      it "finds at end of string" do
        m = WordWatcher.new("who likes #{anise.word}").word_matches_for_action?(:require_approval)
        expect(m[1]).to eq(anise.word)
      end

      it "finds non-letters in place of letters" do
        Fabricate(:watched_word, word: "co(onut", action: WatchedWord.actions[:require_approval])
        m = WordWatcher.new("This co(onut is delicious.").word_matches_for_action?(:require_approval)
        expect(m[1]).to eq("co(onut")
      end

      it "handles * for wildcards" do
        Fabricate(:watched_word, word: "a**le*", action: WatchedWord.actions[:require_approval])
        m = WordWatcher.new("I acknowledge you.").word_matches_for_action?(:require_approval)
        expect(m[1]).to eq("acknowledge")
      end

      context "word boundary" do
        it "handles word boundary" do
          Fabricate(:watched_word, word: "love", action: WatchedWord.actions[:require_approval])
          expect(WordWatcher.new("I Love, bananas.").word_matches_for_action?(:require_approval)[1]).to eq("Love")
          expect(WordWatcher.new("I LOVE; apples.").word_matches_for_action?(:require_approval)[1]).to eq("LOVE")
          expect(WordWatcher.new("love: is a thing.").word_matches_for_action?(:require_approval)[1]).to eq("love")
          expect(WordWatcher.new("I love. oranges").word_matches_for_action?(:require_approval)[1]).to eq("love")
          expect(WordWatcher.new("I :love. pineapples").word_matches_for_action?(:require_approval)[1]).to eq("love")
          expect(WordWatcher.new("peace ,love and understanding.").word_matches_for_action?(:require_approval)[1]).to eq("love")
        end
      end

      context 'multiple matches' do
        context 'non regexp words' do
          it 'lists all matching words' do
            %w{bananas hate hates}.each do |word|
              Fabricate(:watched_word, word: word, action: WatchedWord.actions[:block])
            end
            matches = WordWatcher.new("I hate bananas").word_matches_for_action?(:block, all_matches: true)
            expect(matches).to contain_exactly('hate', 'bananas')
            matches = WordWatcher.new("She hates bananas too").word_matches_for_action?(:block, all_matches: true)
            expect(matches).to contain_exactly('hates', 'bananas')
          end
        end

        context 'regexp words' do
          it 'lists all matching patterns' do
            Fabricate(:watched_word_regexp, word: "(pine)?apples", action: WatchedWord.actions[:block])
            Fabricate(:watched_word_regexp, word: "((move|store)(d)?)|((watch|listen)(ed|ing)?)", action: WatchedWord.actions[:block])

            matches = WordWatcher.new("pine pineapples apples").word_matches_for_action?(:block, all_matches: true)
            expect(matches).to contain_exactly('pineapples', 'apples')

            matches = WordWatcher.new("go watched watch ed ing move d moveed moved moving").word_matches_for_action?(:block, all_matches: true)
            expect(matches).to contain_exactly(*%w{watched watch move moved})
          end
        end
      end

      context "emojis" do
        it "handles emoji" do
          Fabricate(:watched_word, word: ":joy:", action: WatchedWord.actions[:require_approval])
          m = WordWatcher.new("Lots of emojis here :joy:").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq(":joy:")
        end

        it "handles unicode emoji" do
          Fabricate(:watched_word, word: "🎃", action: WatchedWord.actions[:require_approval])
          m = WordWatcher.new("Halloween party! 🎃").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq("🎃")
        end

        it "handles emoji skin tone" do
          Fabricate(:watched_word, word: ":woman:t5:", action: WatchedWord.actions[:require_approval])
          m = WordWatcher.new("To Infinity and beyond! 🚀 :woman:t5:").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq(":woman:t5:")
        end
      end

      context "literal words" do
        it "supports regular expression special characters" do
          Fabricate(
            :watched_word_literal,
            word: '.*hi*.',
            action: WatchedWord.actions[:block]
          )
          m = WordWatcher.new(".*hi*.").word_matches_for_action?(:block)
          expect(m[1]).to eq(".*hi*.")

          m = WordWatcher.new("qqqhi*.").word_matches_for_action?(:block)
          expect(m).to be_nil
        end
      end

      context "regular expressions" do
        it "supports regular expressions on word boundaries" do
          Fabricate(
            :watched_word_regexp,
            word: /\btest\b/,
            word_boundary: true,
            action: WatchedWord.actions[:block]
          )
          m = WordWatcher.new("this is not a test.").word_matches_for_action?(:block)
          expect(m[1]).to eq("test")
          m = WordWatcher.new("this is not a untest.").word_matches_for_action?(:block)
          expect(m).to be_nil
        end

        it "supports regular expressions as a site setting" do
          Fabricate(
            :watched_word_regexp,
            word: /tro[uo]+t/,
            word_boundary: true,
            action: WatchedWord.actions[:require_approval]
          )
          m = WordWatcher.new("Evil Trout is cool").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq("Trout")
          m = WordWatcher.new("Evil Troot is cool").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq("Troot")
          m = WordWatcher.new("trooooooooot").word_matches_for_action?(:require_approval)
          expect(m[1]).to eq("trooooooooot")
        end

        it "support uppercase" do
          Fabricate(
            :watched_word_regexp,
            word: /a\S+ce/,
            action: WatchedWord.actions[:require_approval]
          )

          m = WordWatcher.new('Amazing place').word_matches_for_action?(:require_approval)
          expect(m).to be_nil
          m = WordWatcher.new('Amazing applesauce').word_matches_for_action?(:require_approval)
          expect(m[1]).to eq('applesauce')
          m = WordWatcher.new('Amazing AppleSauce').word_matches_for_action?(:require_approval)
          expect(m[1]).to eq('AppleSauce')
        end
      end

    end
  end

end
