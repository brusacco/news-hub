# frozen_string_literal: true

module AiServices
  class EntryPromptBuilder < ApplicationService
    DESCRIPTION_MAX_LENGTH = 160
    SUMMARY_WORD_RANGE = '40 to 70'
    ARTICLE_WORD_RANGE = '350 to 650'
    MAX_KEYWORDS = 12
    MAX_ENTITIES = 12

    def initialize(entry)
      @entry = entry
    end

    def call
      <<~PROMPT
        You are rewriting a Nintendo news source article for publication on Nintendo News Hub.

        Goals:
        - Produce an original article that keeps the factual meaning of the source without copying its phrasing.
        - Preserve the main entity and search intent from the original title. If the source title contains a core game,
          franchise, developer, or hardware name, keep that exact entity in the rewritten title unless the source text
          clearly proves it is wrong.
        - Prioritize specificity over generic phrasing. Do not replace a precise game or franchise name with a broader term.
        - Write for readers who already follow Nintendo, games, and publishers.

        Editorial rules:
        - Use only facts supported by the provided source text.
        - Do not invent release dates, platforms, quotes, sales numbers, features, or background details.
        - Rewrite quotes into reported speech unless the exact wording is essential and clearly present in the source.
        - Avoid filler, hype, and vague lead-ins.
        - Keep the article focused on the main news angle.

        SEO and structure rules:
        - Write an `ai_title` that is clear, specific, and click-worthy without sounding spammy.
        - Keep `ai_title` concise and front-load the main entity or game when possible.
        - Write an `ai_description` suitable for a meta description, under #{DESCRIPTION_MAX_LENGTH} characters,
          summarizing the core news angle with the main entity included naturally.
        - Write an `ai_summary` of about #{SUMMARY_WORD_RANGE} words for on-page summary use.
        - Write `ai_content` of about #{ARTICLE_WORD_RANGE} words.
        - Open with a strong first paragraph that states the main news clearly.
        - Use short paragraphs that are easy to scan.
        - Naturally include relevant entities such as the game title, franchise, developer, publisher, platform,
          or Nintendo hardware when they are genuinely central to the source.

        Output rules:
        - Return only valid JSON.
        - Do not wrap the JSON in markdown fences.
        - Use this exact JSON shape with double-quoted keys and string values:
          {
            "ai_title": "Your rewritten title",
            "ai_description": "Meta description",
            "ai_summary": "Short summary",
            "keywords": "keyword1,keyword2,keyword3",
            "entities": "entity1,entity2,entity3",
            "ai_content": "Full rewritten article"
          }
        - `keywords` must contain up to #{MAX_KEYWORDS} highly relevant SEO phrases.
        - `entities` must contain up to #{MAX_ENTITIES} specific entities from the source, prioritizing exact games,
          franchises, companies, developers, and hardware names.
        - For `keywords` and `entities`, use comma-separated values with no spaces after commas.
        - Ensure the JSON is syntactically valid before finishing.

        Source metadata:
        - Original title: #{@entry.title}
        - Source name: #{@entry.source_name}
        - Category: #{@entry.category}

        Source article text:
        #{@entry.content}
      PROMPT
    end
  end
end
