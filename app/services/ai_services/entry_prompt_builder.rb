# frozen_string_literal: true

module AiServices
  class EntryPromptBuilder < ApplicationService
    def initialize(entry)
      @entry = entry
    end

    def call
      <<~PROMPT
        Act as a seasoned journalist and subject matter expert in Nintendo news and game development.
        Write a search-optimized article suitable for publication on a professional gaming news website.
        The article should follow SEO best practices and maintain a tone that is informative, authoritative,
        and tailored for an audience familiar with the gaming industry.
        Begin with a strong, SEO-optimized title that includes a relevant keyphrase related to the main topic.
        Start the article with an introductory paragraph that provides background context on the subject,
        including relevant information about the game, developer, or hardware involved. In the body, include a rewritten
        version of any notable quotes or statements using clear, journalistic language.
        Enrich the article with only verified, factual information such as release dates, sales milestones,
        platform history, or developer achievements - do not include speculation or fabricated content.
        Ensure the total word count is at least 300-500 words to support SEO goals, and naturally incorporate keywords
        such as the game title, developer name, and hardware platform (e.g., Nintendo Switch, Nintendo Direct, eShop, etc.).
        The final article should be well-structured, easy to scan, and optimized for both readers and search engines.
        Return the article in a JSON structure like this,
        {ai_title: 'Your Title Here',
        ai_description: 'Short description for meta tags',
        keywords: 'Comma-separated rich SEO keywords for this article',
        entities: 'Comma-separated important entities from the content, like company names, developers, games',
        ai_content: 'Your article content here'}.
        Do not include any additional text or commentary outside of the JSON structure and remove any trailing spaces
        from the keywords and entities JSON fields content (remove the space after the commas).
        Always check the JSON structure for errors and ensure it is valid.

        The text to rewrite is:
        #{@entry.content}
      PROMPT
    end
  end
end
