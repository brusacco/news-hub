# frozen_string_literal: true

class GameDeveloper < ApplicationRecord
  belongs_to :game
  belongs_to :developer

  validates :game_id, uniqueness: { scope: :developer_id }
end
