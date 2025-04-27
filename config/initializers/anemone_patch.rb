# frozen_string_literal: true

# config/initializers/anemone_storage_patch.rb

module Anemone
  module Storage
    class Hash
      def optimize_routes_generation?
        false
      end
    end
  end
end
