# uBlock Origin Filters

## How to Apply

uBlock Origin → Dashboard (gear icon) → **My Filters** tab → paste → **Apply changes**

---

## YouTube Filters

Replaces TubeMod. Keep SponsorBlock and Return YouTube Dislike — those can't be replaced.

```
! ============================================================
! YouTube – TubeMod Replacement Filters for uBlock Origin
! ============================================================

! ─── HEADER ──────────────────────────────────────────────
! Hide microphone/voice search
youtube.com###voice-search-button

! ─── SIDEBAR ─────────────────────────────────────────────
! Shorts links
youtube.com##ytd-guide-entry-renderer:has(> a[title="Shorts"])
youtube.com##ytd-mini-guide-entry-renderer:has(> a[title="Shorts"])
! My Clips
youtube.com##ytd-guide-entry-renderer:has(> a[href="/feed/clips"])
! Downloads / Transfers
youtube.com##ytd-guide-downloads-entry-renderer
youtube.com##ytd-mini-guide-entry-renderer:has(> a[href="/feed/downloads"])
! Explore section (Shopping, Music, Movies & TV, Gaming, etc.)
youtube.com##ytd-guide-section-renderer:has(a[title="Shopping"])
! "More from YouTube" section (Premium, Studio, Music, Kids)
youtube.com##ytd-guide-section-renderer:has(a[href="/premium"])
! Footer links
youtube.com##ytd-guide-renderer #footer

! ─── HOME PAGE ───────────────────────────────────────────
! Shorts shelf
youtube.com##ytd-rich-section-renderer:has(ytm-shorts-lockup-view-model)
! News / Breaking News banners
youtube.com##ytd-rich-section-renderer:has(ytd-statement-banner-renderer)
! Trending shelf (targets section linking to /feed/trending)
youtube.com##ytd-rich-section-renderer:has(a[href="/feed/trending"])
! Playables
youtube.com##ytd-rich-section-renderer:has(a[href*="/playables"])
! Primetime / Movies
youtube.com##ytd-rich-section-renderer:has(a[href="/feed/storefront"])
! Auto-generated mixes (Radio / My Mix — list=RD prefix)
youtube.com##ytd-rich-item-renderer:has(a[href*="list=RD"])

! ─── SUBSCRIPTIONS ───────────────────────────────────────
! Shorts shelf on subscriptions
youtube.com##ytd-rich-section-renderer:has(ytd-reel-shelf-renderer)

! ─── SEARCH ──────────────────────────────────────────────
! Shorts shelves
youtube.com##ytd-reel-shelf-renderer
youtube.com##grid-shelf-view-model:has(ytm-shorts-lockup-view-model)
! "People also searched for"
youtube.com##ytd-search #contents ytd-horizontal-card-list-renderer

! ─── TRENDING PAGE ───────────────────────────────────────
! Shorts mixed into trending
youtube.com##ytd-browse[page-subtype="trending"] ytd-video-renderer:has(a[href*="/shorts/"])

! ─── CHANNEL PAGE ────────────────────────────────────────
! Channel trailer autoplay
youtube.com###c4-player

! ─── VIDEO PAGE ──────────────────────────────────────────
! Join (channel membership) button
youtube.com###sponsor-button
! Download button
youtube.com##ytd-download-button-renderer
! Thanks / Super Thanks button (matched by SVG path prefix)
youtube.com###flexible-item-buttons yt-button-view-model:has(path[d^="M11 17h2v-1h1"])
! Shorts shelf in video description
youtube.com##ytd-structured-description-content-renderer ytd-reel-shelf-renderer
! Live chat replay teaser carousel
youtube.com###teaser-carousel
! Game / product category metadata
youtube.com##ytd-rich-metadata-renderer
! In-player ads container
youtube.com###player-ads
! Offer / upsell module
youtube.com###offer-module
! Related topic chips bar
youtube.com##yt-related-chip-cloud-renderer
! Suggested Shorts in watch sidebar
youtube.com##ytd-watch-next-secondary-results-renderer ytd-reel-shelf-renderer
! Show/hide chat button on live streams
youtube.com###show-hide-button

! ─── TWITCH ──────────────────────────────────────────────
! Block Twitch video ads
twitch.tv##+js(twitch-videoad)
```

### Approximation Notes

- **Home news** — catches `ytd-statement-banner-renderer` (breaking news banners). Other news-type shelves without that element may slip through
- **Home trending** — targets sections linking to `/feed/trending`. TubeMod used SVG icon matching which CSS can't replicate; may need tweaking if YouTube restructures that section
- **Playlist mixes** — matched by `list=RD` URL prefix (YouTube's auto-generated mix format)
- **Thanks button** — matched by SVG path prefix; update `d^=` value if YouTube changes the icon
