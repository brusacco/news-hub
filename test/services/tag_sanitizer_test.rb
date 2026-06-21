# frozen_string_literal: true

require 'test_helper'

class TagSanitizerTest < ActiveSupport::TestCase
  test 'filters generic platform region and short tags' do
    tags = ['Nintendo Switch 2', 'Nintendo', 'Switch', 'PC', 'US', 'S', 'Europe', 'Devil May Cry 5']

    assert_equal ['Devil May Cry 5'], TagSanitizer.call(tags)
  end

  test 'canonicalizes case and deduplicates case-insensitively' do
    tags = ['CAPCOM', 'Capcom', 'devil may cry 5', 'PC-9801']

    assert_equal ['Capcom', 'Devil May Cry 5', 'PC-9801'], TagSanitizer.call(tags)
  end

  test 'keeps specific multi-word titles while blocking generic single words' do
    tags = ['Star Fox', 'Fox', 'Citizen Sleeper 2', 'Run', 'Kiyo: Bunny Tyranny']

    assert_equal ['Star Fox', 'Citizen Sleeper 2', 'Kiyo: Bunny Tyranny'], TagSanitizer.call(tags)
  end

  test 'filters noisy generated tags from Mario Galaxy article' do
    tags = [
      'Peach', 'Super Mario Galaxy', 'Mario', 'Super Mario Galaxy 2', 'Wii', 'Koji Kondo',
      'Shigeru Miyamoto', 'Wii U', 'Super Mario Sunshine', 'Pro Controller', 'Mushroom',
      'Bowser', 'Super Mario', 'Tokyo', 'Red', '3D Mario', 'Sunshine', 'Yoshiaki Koizumi',
      'Amiibo', 'Super Mario 3D All-Stars', 'Miyamoto', 'Ray', 'Comet Observatory', 'Kondo',
      'Rosalina', 'Control', 'Galaxy 2', 'Gamestop', 'Lumas', 'Mother', 'Boo', 'Coin',
      'Franchise', 'Joy-Cons', 'Sometimes You', 'Super Mario Galaxy Movie', 'Mario Galaxy',
      'Mario Galaxy 2', 'Luma', 'The Super Mario Galaxy Movie', '3D All-Stars',
      'Mario 3D All-Stars', 'Storybook', 'Mario Galaxy Movie', 'Happy', 'Kid', 'Boo Mario',
      'Feel', 'Joy', 'Cursor', 'Mahito Yokota', 'Collect', 'Power Stars', 'Switch Port',
      'Soundtrack', 'Ages', 'Nintendo Ead', 'Mario Franchise', 'Mario Series', 'Console',
      'Egg', 'Rosalina’S Storybook', 'Ice', 'Time', 'Nintendo Ead Tokyo'
    ]

    assert_equal [
      'Peach', 'Super Mario Galaxy', 'Mario', 'Super Mario Galaxy 2', 'Koji Kondo',
      'Shigeru Miyamoto', 'Super Mario Sunshine', 'Bowser', 'Super Mario', '3D Mario',
      'Yoshiaki Koizumi', 'Super Mario 3D All-Stars', 'Comet Observatory', 'Rosalina',
      'Boo', 'Sometimes You', 'Super Mario Galaxy Movie', 'The Super Mario Galaxy Movie',
      '3D All-Stars', 'Mario 3D All-Stars', 'Mario Galaxy Movie', 'Boo Mario', 'Mahito Yokota',
      'Power Stars', 'Rosalina’S Storybook', 'Nintendo Ead Tokyo'
    ], TagSanitizer.call(tags)
  end
end
