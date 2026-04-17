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
- Core models are [app/models/entry.rb](app/models/entry.rb), [app/models/tag.rb](app/models/tag.rb), [app/models/site.rb](app/models/site.rb), and [app/models/topic.rb](app/models/topic.rb).
- Admin lives in [app/admin](app/admin) with Devise + ActiveAdmin.
- Business logic is primarily in [app/services](app/services).
- Scheduled tasks are defined in [config/schedule.rb](config/schedule.rb) using `whenever`.

## Conventions To Follow

- Prefer service objects for non-trivial business logic. A base service exists at [app/services/application_service.rb](app/services/application_service.rb), but not every existing service uses it; match the local pattern of the area you are editing.
- Preserve slug-based routing for entries and tags. Both use FriendlyId.
- Preserve ActiveAdmin search/filter support when changing models: check `ransackable_attributes` and `ransackable_associations` in the affected model.
- Keep entry queries eager-loaded with `:tags` and `:site` when rendering lists or detail pages. Existing controller code and the review docs treat N+1 regressions here as a real issue.
- Search behavior is simple SQL `LIKE` matching, not full-text search. See [app/services/entry_search_service.rb](app/services/entry_search_service.rb) and [app/services/autocomplete_search_service.rb](app/services/autocomplete_search_service.rb).
- Tag updates can enqueue background work through `perform_later`; review [app/models/tag.rb](app/models/tag.rb) and [app/jobs/tags](app/jobs/tags) before changing tag lifecycle behavior.

## Pitfalls

- Do not assume the background job backend is fully configured in all environments. Jobs are enqueued with Active Job, and production scheduling exists, but the production queue adapter is still commented out in [config/environments/production.rb](config/environments/production.rb).
- Do not remove or bypass the Node-based extraction path without checking the extractor services first; scraping and content parsing depend on it.
- Be careful editing entry SEO/meta behavior. Public article pages build titles, descriptions, and keywords in controllers and views, not only in models.
- Development caching is toggle-based via `tmp/caching-dev.txt`; cache-related behavior can differ locally.
- Production uses Redis for the cache store; development does not.

## Useful Docs

- Architecture and quality review: [CODE_REVIEW.md](CODE_REVIEW.md)
- Shorter review summary: [CODE_REVIEW_SUMMARY.md](CODE_REVIEW_SUMMARY.md)
- UI and design guidance: [DESIGN_ANALYSIS.md](DESIGN_ANALYSIS.md)
- SEO guidance: [SEO_CHECKLIST.md](SEO_CHECKLIST.md)
- Data model reference: [db/schema.rb](db/schema.rb)

## Good First Reads For Changes

- Search or entry listing work: [app/controllers/entries_controller.rb](app/controllers/entries_controller.rb), [app/controllers/home_controller.rb](app/controllers/home_controller.rb), [app/services/entry_search_service.rb](app/services/entry_search_service.rb)
- Extraction or crawling work: [app/services/web_extractor_services](app/services/web_extractor_services), [lib/readability.js](lib/readability.js)
- AI content generation work: [app/models/entry.rb](app/models/entry.rb), [app/services/ai_services/open_ai_query.rb](app/services/ai_services/open_ai_query.rb)
- Tagging work: [app/models/tag.rb](app/models/tag.rb), [app/jobs/tags](app/jobs/tags)