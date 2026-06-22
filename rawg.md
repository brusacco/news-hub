# RAWG Imports

This app imports Nintendo Switch game metadata from the RAWG API.

The RAWG integration stores games in `games`, genres in `genres`, game-to-genre links in `game_genres`, and
news-to-game links in `entry_games`. RAWG payloads are also kept in JSON columns so we can backfill relations or add
fields later without re-fetching everything.

## Environment

All RAWG tasks require Rails and the production environment when running on the server:

```bash
RAILS_ENV=production bin/rails db:migrate
```

Tasks that call RAWG require:

```bash
RAWG_API_KEY='your-key'
```

Do not commit API keys into the repo.

## Recommended Full Import

Run this after deploying RAWG migrations, or when rebuilding RAWG data:

```bash
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_games
RAILS_ENV=production bin/rails rawg:sync_game_genres
RAILS_ENV=production bin/rails games:populate_name_tags LIMIT=all
RAILS_ENV=production bin/rails games:link_entries LIMIT=all
RAILS_ENV=production bundle exec whenever --update-crontab
```

The order matters:

1. `rawg:import_genres` imports full genre records, including `image_background`.
2. `rawg:import_games` imports Nintendo Switch games and links them to genres from the game payload.
3. `rawg:sync_game_genres` backfills or repairs `game_genres` from stored `games.rawg_genres`.
4. `games:populate_name_tags` fills `Game` name tags used by the news/game matcher.
5. `games:link_entries` links news entries to imported games.
6. `whenever --update-crontab` installs the cron schedule that keeps new entries linked over time.

After deploying view/style changes for `/games`, `/genres`, or game detail pages, also rebuild assets:

```bash
RAILS_ENV=production bin/rails assets:clobber assets:precompile
touch tmp/restart.txt
```

## Tasks

### `rawg:import_genres`

Imports all RAWG genres from `/api/genres`.

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres
```

By default, this follows RAWG pagination until the API returns no `next` page.

Optional variables:

```bash
PAGES=1
PAGE_SIZE=40
```

Examples:

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres PAGES=1
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres PAGE_SIZE=20
```

This task updates:

- `genres.rawg_id`
- `genres.name`
- `genres.slug`
- `genres.games_count`
- `genres.image_background`
- `genres.raw_data`

Use this task when genre cards show fallback images. The games endpoint often only sends `id`, `name`, and `slug` for
genres; the genres endpoint sends the image payload.

### `rawg:import_games`

Imports Nintendo Switch games from `/api/games` with `platforms=7`.

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_games
```

By default, this follows RAWG pagination until the API returns no `next` page.

Optional variables:

```bash
PAGES=10
PAGE_SIZE=40
ORDERING='-released'
```

Examples:

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_games PAGES=10
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_games ORDERING='name'
```

This task updates or creates `Game` rows by `rawg_id`, so reruns are safe and should not duplicate games.

It also stores the genre payload in `games.rawg_genres` and syncs `game_genres` for each imported game.

Newly imported games also get a default `name_tags` value when the game has no name tags yet. This uses
`Game.default_name_tag_for(game.name)` and preserves manually curated name tags.

### `games:populate_name_tags`

Populates `Game` name tags using `acts_as_taggable_on :name_tags`.

```bash
RAILS_ENV=production bin/rails games:populate_name_tags
```

By default, this only fills games that do not already have name tags.

Optional variables:

```bash
LIMIT=all
FORCE=true
```

Examples:

```bash
RAILS_ENV=production bin/rails games:populate_name_tags LIMIT=all
RAILS_ENV=production bin/rails games:populate_name_tags LIMIT=all FORCE=true
```

Use `FORCE=true` only when you want to overwrite manually curated game name tags.

### `games:populate_name_tag`

Populates one game's name tags.

```bash
RAILS_ENV=production bin/rails games:populate_name_tag GAME='cyberpunk-2077'
RAILS_ENV=production bin/rails games:populate_name_tag GAME_ID=123 FORCE=true
```

### `rawg:sync_game_genres`

Backfills the many-to-many relation from stored `games.rawg_genres`.

```bash
RAILS_ENV=production bin/rails rawg:sync_game_genres
```

Optional variables:

```bash
BATCH_SIZE=500
```

Use this task after:

- Adding the `genres` or `game_genres` tables.
- Renaming `games.genres` to `games.rawg_genres`.
- Importing games before genre relations existed.
- Fixing or reimporting genre data.

This task does not call RAWG.

It preserves enriched genre fields. If a game payload only has `id`, `name`, and `slug`, it will not clear an existing
`genres.image_background`, `genres.games_count`, or full `genres.raw_data`.

### `games:link_entries`

Links news entries to games through the `entry_games` join table.

```bash
RAILS_ENV=production bin/rails games:link_entries
```

By default this processes recent entries in the same 4-year scope used by the tagger, capped by `LIMIT=500`.

Optional variables:

```bash
LIMIT=all
ALL=true
GAME_ID=123
GAME='cyberpunk-2077'
```

Examples:

```bash
RAILS_ENV=production bin/rails games:link_entries LIMIT=all
RAILS_ENV=production bin/rails games:link_entries GAME='cyberpunk-2077' LIMIT=all
```

Use this after importing games, adding the `entry_games` table, or changing game matching logic.

When `GAME` or `GAME_ID` is provided, the task updates links for only that game and preserves existing links for other
games. Without a selected game, stale links are replaced with the current matcher results for each processed entry.

### `games:link_entry`

Links one entry to games.

```bash
RAILS_ENV=production bin/rails games:link_entry ENTRY_ID=123
RAILS_ENV=production bin/rails games:link_entry ENTRY_ID=123 GAME='cyberpunk-2077'
```

### `games:cleanup_entry_links`

Deletes all entry-game links. This is a dry run by default.

```bash
RAILS_ENV=production bin/rails games:cleanup_entry_links
RAILS_ENV=production bin/rails games:cleanup_entry_links DRY_RUN=false
```

Use this only when you want to fully rebuild entry-game links from scratch:

```bash
RAILS_ENV=production bin/rails games:cleanup_entry_links DRY_RUN=false
RAILS_ENV=production bin/rails games:link_entries LIMIT=all
```

## Game Matching Rules

Entry-to-game matching is deterministic and does not call RAWG or AI.

The matcher checks exact game names and game `name_tags` against entry text using word boundaries. It is intentionally
stricter than normal article tags because game names can be short or generic.

Match sources and confidence:

- `title`: 100
- `ai_title`: 95
- `title_tags`: 90
- `tags`: 75
- `description`: 65
- `ai_description`: 65
- `summary`: 55
- `ai_summary`: 55
- `content`: 45

Short game names are only trusted in strong sources such as `title`, `ai_title`, `title_tags`, or `tags`. This avoids
bad content matches for names like `Ys`, `OFF`, `One`, or other short/common words.

Examples:

- `Cyberpunk 2077` in an article title links the entry to the `Cyberpunk 2077` game with high confidence.
- `Cyberpunk` alone does not link to `Cyberpunk 2077`.
- `Ys` in body content does not link by itself.
- `Ys` in title tags can link because title tags are high-signal.
- `Breath of the Wild` can link to `The Legend of Zelda: Breath of the Wild` when `Breath of the Wild` is present in
  that game's `name_tags`.

The tagger now calls the same matcher after processing an entry, so new or retagged entries refresh their game links
automatically. The standalone `games:link_entries` task remains the source of truth for backfills and repairs.

## Idempotency

These tasks are designed to be rerun.

- Games are upserted with `Game.find_or_initialize_by(rawg_id: ...)`.
- Genres are upserted with `Genre.find_or_initialize_by(rawg_id: ...)`.
- Game-to-genre links are assigned through the `game.genres` association.
- Entry-to-game links are upserted through `entry_games`.
- Duplicate `game_genres` rows are prevented by the unique index on `[game_id, genre_id]`.
- Duplicate `entry_games` rows are prevented by the unique index on `[entry_id, game_id]`.

If RAWG changes metadata, rerunning the import updates local rows.

## Data Model

`Game`

- RAWG identity: `rawg_id`, `slug`, `name`
- Main fields: `released`, `background_image`, `rating`, `metacritic`, `playtime`
- JSON payload fields: `platforms`, `rawg_genres`, `stores`, `raw_data`
- Tag context: `acts_as_taggable_on :name_tags`
- Relation: `has_many :genres, through: :game_genres`
- Relation: `has_many :entries, through: :entry_games`

`EntryGame`

- Join table between `entries` and `games`
- Stores `match_source`, `confidence`, and `matched_text`
- Unique index on `[entry_id, game_id]`
- Powers related news on game pages and related games on article pages

`Genre`

- RAWG identity: `rawg_id`, `slug`, `name`
- Main fields: `games_count`, `image_background`
- JSON payload field: `raw_data`
- Route param: `slug`
- Relation: `has_many :games, through: :game_genres`

`GameGenre`

- Join table between `games` and `genres`
- Unique index on `[game_id, genre_id]`

## Public Pages

The imported data powers:

- `/games`
- `/games/:slug`
- `/genres`
- `/genres/:slug`
- Related games on `/news/:slug`
- Related news on `/games/:slug`

The genre cards use `genres.image_background`. If cards show the Nintendo fallback image, run:

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres
```

If `/genres/:slug` has no games after importing games, run:

```bash
RAILS_ENV=production bin/rails rawg:sync_game_genres
```

If `/games/:slug` has no related news after importing games, run:

```bash
RAILS_ENV=production bin/rails games:link_entries LIMIT=all
```

If a news article does not show a related game but the title clearly contains the game name, run a targeted check:

```bash
RAILS_ENV=production bin/rails games:link_entry ENTRY_ID=123
```

## Console Checks

Check whether genres have images:

```ruby
Genre.count
Genre.where.not(image_background: [nil, ""]).count
Genre.limit(5).pluck(:name, :image_background)
```

Check a genre's linked games:

```ruby
genre = Genre.find_by!(slug: "action")
genre.games.recent.limit(10).pluck(:id, :name, :slug)
```

Check games that still have RAWG genre payloads:

```ruby
Game.where.not(rawg_genres: nil).count
```

Check whether entries are linked to games:

```ruby
EntryGame.count
EntryGame.strongest_first.limit(10).pluck(:entry_id, :game_id, :match_source, :confidence, :matched_text)
```

Check game name tags:

```ruby
game = Game.find_by!(slug: "cyberpunk-2077")
game.name_tag_list
```

Check news linked to a game:

```ruby
game = Game.find_by!(slug: "cyberpunk-2077")
game.entries.recent.limit(10).pluck(:id, :title, :slug, :published_at)
```

Check games linked to a news entry:

```ruby
entry = Entry.friendly.find("some-news-slug")
entry.entry_games.strongest_first.includes(:game).map { |link| [link.game.name, link.match_source, link.confidence] }
```

Force-link one game scan for all entries:

```bash
RAILS_ENV=production bin/rails games:link_entries GAME='cyberpunk-2077' LIMIT=all
```

## Cron

Scheduled tasks live in `config/schedule.rb`.

The hourly schedule includes:

```ruby
rake 'tagger'
rake 'tagger:title_tags'
rake 'tagger:untagged'
rake 'games:link_entries'
```

Production uses cron through `whenever`; there is no required background job worker for these imports/linking tasks.
After changing the schedule, update the crontab:

```bash
RAILS_ENV=production bundle exec whenever --update-crontab
```
