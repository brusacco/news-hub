# RAWG Imports

This app imports Nintendo Switch game metadata from the RAWG API.

The RAWG integration stores games in `games`, genres in `genres`, and the many-to-many relation in
`game_genres`. RAWG payloads are also kept in JSON columns so we can backfill relations or add fields later without
re-fetching everything.

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
```

The order matters:

1. `rawg:import_genres` imports full genre records, including `image_background`.
2. `rawg:import_games` imports Nintendo Switch games and links them to genres from the game payload.
3. `rawg:sync_game_genres` backfills or repairs `game_genres` from stored `games.rawg_genres`.

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

## Idempotency

These tasks are designed to be rerun.

- Games are upserted with `Game.find_or_initialize_by(rawg_id: ...)`.
- Genres are upserted with `Genre.find_or_initialize_by(rawg_id: ...)`.
- Game-to-genre links are assigned through the `game.genres` association.
- Duplicate `game_genres` rows are prevented by the unique index on `[game_id, genre_id]`.

If RAWG changes metadata, rerunning the import updates local rows.

## Data Model

`Game`

- RAWG identity: `rawg_id`, `slug`, `name`
- Main fields: `released`, `background_image`, `rating`, `metacritic`, `playtime`
- JSON payload fields: `platforms`, `rawg_genres`, `stores`, `raw_data`
- Relation: `has_many :genres, through: :game_genres`

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
- `/genres`
- `/genres/:slug`

The genre cards use `genres.image_background`. If cards show the Nintendo fallback image, run:

```bash
RAILS_ENV=production RAWG_API_KEY='your-key' bin/rails rawg:import_genres
```

If `/genres/:slug` has no games after importing games, run:

```bash
RAILS_ENV=production bin/rails rawg:sync_game_genres
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
