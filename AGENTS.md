# AGENTS.md

Guidance for AI coding agents working in this Rails application.

## Start Here

- Ignore the root README for implementation guidance; it is still the default Rails placeholder.
- Use `bin/setup` for first-time setup or when dependencies/schema may be stale.
- Use `bin/dev` for local development. It starts the Rails server and `tailwindcss:watch` through Foreman.
- Run tests with `bin/rails test`.
- Run lint checks with `bundle exec rubocop`.

## Runtime Facts

- Ruby: `3.1.6`
- Rails: `7.1`
- Database in development and test: SQLite
- Frontend stack: importmap + Turbo + Stimulus + Tailwind via `tailwindcss-rails`
- Node.js is also required for content extraction code under [lib/readability.js](lib/readability.js) and the services in [app/services/web_extractor_services](app/services/web_extractor_services).

## App Shape

- Public article routes live under `/news`, backed by [config/routes.rb](config/routes.rb).
- Core news models are [app/models/entry.rb](app/models/entry.rb), [app/models/tag.rb](app/models/tag.rb), [app/models/site.rb](app/models/site.rb), and [app/models/topic.rb](app/models/topic.rb).
- RAWG game models are [app/models/game.rb](app/models/game.rb), [app/models/screenshot.rb](app/models/screenshot.rb), [app/models/genre.rb](app/models/genre.rb), [app/models/game_genre.rb](app/models/game_genre.rb), and [app/models/entry_game.rb](app/models/entry_game.rb).
- Admin lives in [app/admin](app/admin) with Devise + ActiveAdmin.
- Business logic is primarily in [app/services](app/services).
- Scheduled tasks are defined in [config/schedule.rb](config/schedule.rb) using `whenever`.

## Conventions To Follow

- Prefer service objects for non-trivial business logic. A base service exists at [app/services/application_service.rb](app/services/application_service.rb), but not every existing service uses it; match the local pattern of the area you are editing.
- Preserve slug-based routing for entries, tags, games, and genres. Entries and tags use FriendlyId; games and genres use their stored `slug` via `to_param`.
- Preserve ActiveAdmin search/filter support when changing models: check `ransackable_attributes` and `ransackable_associations` in the affected model.
- Keep entry queries eager-loaded with `:tags` and `:site` when rendering lists or detail pages. Existing controller code and the review docs treat N+1 regressions here as a real issue.
- Keep game queries eager-loaded with `:genres` and, when matching games to entries, preload `:name_tags`.
- Search behavior is simple SQL `LIKE` matching, not full-text search. See [app/services/entry_search_service.rb](app/services/entry_search_service.rb) and [app/services/autocomplete_search_service.rb](app/services/autocomplete_search_service.rb).
- Tag updates can enqueue background work through `perform_later`; review [app/models/tag.rb](app/models/tag.rb) and [app/jobs/tags](app/jobs/tags) before changing tag lifecycle behavior.
- Games use `acts_as_taggable_on :name_tags`. Do not add a `games.name_tag` column; use `game.name_tag_list`.

## RAWG And Games

- RAWG documentation lives in [rawg.md](rawg.md). Update it whenever changing RAWG imports, game/genre relations, game matching, or related rake tasks.
- RAWG imports are implemented in [app/services/rawg_services](app/services/rawg_services) and [lib/tasks/rawg.rake](lib/tasks/rawg.rake).
- Public game routes are `/games`, `/games/:slug`, `/genres`, and `/genres/:slug`.
- `Game` and `Genre` rows are upserted by `rawg_id`; rerunning imports should not duplicate them.
- `Screenshot` rows are upserted by `game_id + rawg_id`; rerunning screenshot imports should not duplicate them.
- `GameGenre` links games to genres. `EntryGame` links news entries to games and stores `match_source`, `confidence`, and `matched_text`.
- `GameMatcher` in [app/services/game_matcher.rb](app/services/game_matcher.rb) links entries to games using exact word-boundary matches against `game.name` and `game.name_tags`.
- Game matching is deterministic and does not call AI or RAWG. Keep it strict: short game names should only match high-signal sources like title, `ai_title`, tags, or title tags.
- The tagger now refreshes game links for processed entries, but `games:link_entries` is still the backfill/repair task.
- Important game tasks:
  - `rawg:import_genres`
  - `rawg:import_games`
  - `rawg:import_game_details`
  - `rawg:import_screenshots`
  - `rawg:sync_game_genres`
  - `games:populate_name_tags`
  - `games:populate_name_tag`
  - `games:link_entries`
  - `games:link_entry`
  - `games:cleanup_entry_links`

## Tagging And Related Content

- `Entry` uses `acts_as_taggable_on :tags, :title_tags`.
- Title tags are high-signal and drive related articles; avoid falling back to broad normal tags for related news unless intentionally changing relevance behavior.
- Game `name_tags` are separate from entry `title_tags`. They provide alternate exact game names, for example matching `Breath of the Wild` to `The Legend of Zelda: Breath of the Wild`.
- Entry pages can show related games from `entry_games`; game pages can show related news from `entry_games`.
- If related games/news are missing after importing games, run `RAILS_ENV=production bin/rails games:link_entries LIMIT=all`.

## Pitfalls

- Do not assume the background job backend is fully configured in all environments. Jobs are enqueued with Active Job, and production scheduling exists, but the production queue adapter is still commented out in [config/environments/production.rb](config/environments/production.rb).
- Do not remove or bypass the Node-based extraction path without checking the extractor services first; scraping and content parsing depend on it.
- Be careful editing entry SEO/meta behavior. Public article pages build titles, descriptions, and keywords in controllers and views, not only in models.
- Development caching is toggle-based via `tmp/caching-dev.txt`; cache-related behavior can differ locally.
- Production uses Redis for the cache store; development does not.
- Production does not compile missing assets at runtime (`config.assets.compile = false`). After changing Tailwind-heavy views, run `RAILS_ENV=production bin/rails assets:clobber assets:precompile` and restart the app.
- Production scheduling relies on cron via `whenever`, not a fully configured background job worker. After editing [config/schedule.rb](config/schedule.rb), run `RAILS_ENV=production bundle exec whenever --update-crontab`.

## Useful Docs

- Architecture and quality review: [CODE_REVIEW.md](CODE_REVIEW.md)
- Shorter review summary: [CODE_REVIEW_SUMMARY.md](CODE_REVIEW_SUMMARY.md)
- UI and design guidance: [DESIGN_ANALYSIS.md](DESIGN_ANALYSIS.md)
- SEO guidance: [SEO_CHECKLIST.md](SEO_CHECKLIST.md)
- RAWG import and game-linking guidance: [rawg.md](rawg.md)
- Data model reference: [db/schema.rb](db/schema.rb)

## Good First Reads For Changes

- Search or entry listing work: [app/controllers/entries_controller.rb](app/controllers/entries_controller.rb), [app/controllers/home_controller.rb](app/controllers/home_controller.rb), [app/services/entry_search_service.rb](app/services/entry_search_service.rb)
- Extraction or crawling work: [app/services/web_extractor_services](app/services/web_extractor_services), [lib/readability.js](lib/readability.js)
- AI content generation work: [app/models/entry.rb](app/models/entry.rb), [app/services/ai_services/open_ai_query.rb](app/services/ai_services/open_ai_query.rb)
- Tagging work: [app/models/tag.rb](app/models/tag.rb), [app/jobs/tags](app/jobs/tags)
- Game/genre import work: [rawg.md](rawg.md), [app/models/game.rb](app/models/game.rb), [app/models/genre.rb](app/models/genre.rb), [app/services/rawg_services](app/services/rawg_services), [lib/tasks/rawg.rake](lib/tasks/rawg.rake)
- Entry-to-game linking work: [app/services/game_matcher.rb](app/services/game_matcher.rb), [app/models/entry_game.rb](app/models/entry_game.rb), [lib/tasks/games.rake](lib/tasks/games.rake), [lib/tasks/tagger.rake](lib/tasks/tagger.rake)
