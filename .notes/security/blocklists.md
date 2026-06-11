# Blocklists for uBlock Origin & AdGuard Home

## Privacy & Tracking Enhancements

**Lists (in order):**
1. Fanboy's Annoyance - Blocks social media widgets, annoyances
2. Cookie Monster - Blocks cookie banners and consent nags
3. I Don't Care About Cookies - Blocks GDPR/cookie consent popups

```
https://easylist.to/easylist/fanboy-annoyance.txt
https://secure.fanboy.co.nz/fanboy-cookiemonster.txt
https://www.i-dont-care-about-cookies.eu/abp/
```

## uBlock Origin Filters (Recommended)

**Lists (in order):**
1. Unbreak - Fixes sites broken by other filters
2. ABP Anti-CV - Blocks circumvention techniques used to bypass filters

```
https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt
https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt
```

## Anti-Phishing & Malware

**Lists (in order):**
1. URLhaus - Blocks malware and phishing URLs

```
https://gitlab.com/curben/urlhaus-filter/-/raw/master/urlhaus-filter-online.txt
```

## HaGeZi Safe Variants

**About HaGeZi:** Personal blocklist with multiple safety tiers. Choose based on your tolerance for occasional breakage.

### HaGeZi Light

**Best for:** Size-conscious environments without local admin oversight
- Blocks ads, tracking, metrics, malware
- **Entries:** 83,129 domains
- **Blocking Type:** Relaxed
- **Limitation:** Does not block error trackers (Firebase, Sentry, etc.)

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/light.txt
```

### HaGeZi Normal

**Best for:** Most users seeking good protection without significant restrictions
- Adds affiliate domains and phishing to Light
- **Entries:** 264,594 domains
- **Blocking Type:** Relaxed/Balanced
- **Limitation:** Does not block error trackers

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/normal.txt
```

### HaGeZi Pro

**Best for:** Problem-free ad-blocking with solid privacy
- Adds cryptojacking, scams, error trackers
- **Entries:** 344,249 domains
- **Blocking Type:** Balanced
- **Features:** Includes error tracker blocking (Firebase, Sentry)
- **Recommendation:** Creator's recommended version for problem-free operation

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt
```

## HaGeZi Specialized Additions

**Note:** These are separate from the mainline variants and provide additional specialized blocking not fully covered by HaGeZi Pro/Light/Normal.

### HaGeZi Specialized - Safe Tier

**Best for:** Adding protection without breakage risk

#### HaGeZi Fake

**Best for:** Extra scam/trap/fake protection
**Blocks:** Phishing, counterfeit shops, cost traps
- **Entries:** 14,023 compressed domains
- Safe, rarely breaks legitimate sites

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt
```

#### HaGeZi Pop-Up Ads

**Best for:** Blocking annoying pop-ups
**Blocks:** Malicious and annoying pop-up advertising
- **Entries:** 63,633 compressed domains
- Safe, targeted blocking with minimal breakage

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt
```

#### HaGeZi Social Networks

**Best for:** Extra social media tracker blocking
**Blocks:** Social media platforms and trackers
- **Entries:** 886 compressed domains
- Includes: Facebook, TikTok, Instagram, X (Twitter), Snapchat
- Excludes: Messaging apps and streaming platforms

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/social.txt
```

### HaGeZi Specialized - Moderate Tier

**Best for:** Enhanced protection with occasional breakage possible

#### HaGeZi Most Abused TLDs

**Best for:** Blocking scam/spam domains before major lists catch them
**Blocks:** Top-level domains with poor reputation
- Multiple format variants for different adblockers
- Rare breakage but significantly improves security

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/spam-tlds.txt
```

#### HaGeZi Dynamic DNS

**Best for:** Blocking malicious dynamic DNS services
**Blocks:** Known malicious dynamic DNS abuse
- **Entries:** 1,471 compressed domains
- Minimal breakage risk

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/dyndns.txt
```

#### HaGeZi Threat Intelligence Feeds (TIF)

**Best for:** Threat database blocking
**Blocks:** Malware, cryptojacking, scams, spam, phishing

##### TIF Full
- **Entries:** 619,966 (very resource-intensive)

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt
```

##### TIF Medium
- **Entries:** 269,525 compressed domains (recommended for most systems)

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.medium.txt
```

##### TIF Mini
- **Entries:** 121,585 compressed domains (lightweight option)

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.mini.txt
```

#### HaGeZi URL Shortener

**Best for:** Blocking URL shorteners (security-conscious)
**Blocks:** Link obfuscation services
- **Entries:** 9,510 compressed domains
- Moderate breakage: some sites use shorteners legitimately

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/urlshortener.txt
```

#### HaGeZi DoH/VPN/TOR/Proxy Bypass

**Best for:** Prevent methods to bypass your DNS
**Blocks:** Methods to circumvent your DNS filtering
- **Complete Edition:** 6,236 compressed domains
- **DNS-only Edition:** 3,845 domains
- Prevents: DoH providers, VPN services, TOR nodes, proxy bypass methods

```
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/doh-vpn-proxy-bypass.txt
```

## Complete List (Recommended)

**HaGeZi Pro + All Specialized Enhancements**

This combines HaGeZi Pro (comprehensive ad/tracking/malware/phishing blocking) with all specialized lists except social & proxy bypass:

```
https://easylist.to/easylist/fanboy-annoyance.txt
https://secure.fanboy.co.nz/fanboy-cookiemonster.txt
https://www.i-dont-care-about-cookies.eu/abp/
https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt
https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt
https://gitlab.com/curben/urlhaus-filter/-/raw/master/urlhaus-filter-online.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/spam-tlds.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/dyndns.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.medium.txt
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/urlshortener.txt
```

## Twitch Ad Blocking

**Note:** Standard blocklists cannot reliably block Twitch ads without breaking streams, as Twitch serves ads through the same CDN as content.

### uBlock Origin with Custom Script (Recommended)

**Best for:** Blocking all Twitch ad types (pre-roll, mid-roll, post-roll)

**Step 1: Configure userResourceLocation**
1. Open uBlock Origin Dashboard (click uBlock icon → Dashboard)
2. Go to **Settings** tab
3. Scroll down to **Advanced settings**
4. Find `userResourceLocation` setting
5. Set it to:
   ```
   https://raw.githubusercontent.com/pixeltris/TwitchAdSolutions/0863c6d74b98b5e8349382f508412a9005f50c57/vaft/vaft-ublock-origin.js
   ```

**Step 2: Add custom filter**
1. Go to **My filters** tab
2. Add this line:
   ```
   twitch.tv##+js(twitch-videoad)
   ```
3. Click "Apply changes"
4. Refresh Twitch

**Important:** This is an ongoing arms race with Twitch. Keep scripts updated and expect occasional breakages as Twitch changes ad delivery methods. See [TwitchAdSolutions](https://github.com/pixeltris/TwitchAdSolutions) for the latest working solutions.

## How to Use in uBlock Origin

1. Open uBlock Origin settings (click the uBlock icon → Settings (gear icons)).
2. Go to **Filter lists** tab.
3. Scroll to bottom and look for "**Import**" section.
4. Copy and paste any section above into the import field.
5. Click "**Apply changes**" blue button at the top after.
6. uBlock will automatically add all URLs from the pasted block.
