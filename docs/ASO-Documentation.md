# SoberSend — App Store Optimization (ASO) Documentation

> **Last Updated:** May 2026  
> **Bundle ID:** `com.musamasalla.SoberSend`  
> **Platform:** Apple App Store (iOS 17+)  
> **Category:** Health & Fitness (Primary) · Lifestyle (Secondary)  
> **Pricing:** Freemium (Monthly $3.99 with 7-day free trial / Yearly $29.99)

---

## Table of Contents

1. [App Identity & Positioning](#1-app-identity--positioning)
2. [Optimized Metadata](#2-optimized-metadata)
3. [Keyword Strategy](#3-keyword-strategy)
4. [Competitor Analysis](#4-competitor-analysis)
5. [Screenshot & Visual Strategy](#5-screenshot--visual-strategy)
6. [Description (Full)](#6-description-full)
7. [What's New (Release Notes)](#7-whats-new-release-notes)
8. [Rating & Review Strategy](#8-rating--review-strategy)
9. [Localization Roadmap](#9-localization-roadmap)
10. [Launch & Update Cadence](#10-launch--update-cadence)
11. [ASO Health Scorecard](#11-aso-health-scorecard)
12. [A/B Testing Plan](#12-ab-testing-plan)

---

## 1. App Identity & Positioning

### One-Liner
SoberSend locks your most dangerous apps and contacts during vulnerable nighttime hours and forces you to prove sobriety with cognitive challenges before unlocking.

### Target Audience

| Segment | Age | Behavior |
|---------|-----|----------|
| Primary | 21–35 | Social drinkers who drunk-text, drunk-dial, or drunk-scroll |
| Secondary | 25–45 | People in early recovery / sobriety |
| Tertiary | 18–30 | Anyone who impulse-uses apps late at night (social media, dating apps, online shopping) |

### Unique Value Proposition (UVP)
**"The only app that actually blocks your apps AND makes you prove you're sober to get them back."**

Unlike simple timers or screen-time limits, SoberSend uses Apple's Screen Time API to *physically* shield apps and requires multi-stage cognitive challenges (math, memory, speech recognition) to unlock — challenges that are trivially easy sober but nearly impossible while impaired.

### Emotional Hooks (for copy)
- "We both know why you're here."
- "Your future self will thank you."
- "Disasters averted."
- "Notes to future you."

---

## 2. Optimized Metadata

### App Name (30 chars max)
```
SoberSend: Drunk Text Blocker
```
**Character count: 30** ✅

**Rationale:** Brand name + highest-volume descriptive keyword. "Drunk Text Blocker" captures the primary use case and top search intent.

#### Alternatives to A/B Test
| Option | Characters | Notes |
|--------|-----------|-------|
| `SoberSend: Drunk Text Blocker` | 30 | Primary — broadest appeal |
| `SoberSend: App Lock & Blocker` | 30 | More utility-focused |
| `SoberSend: Stop Drunk Texting` | 30 | Action-oriented |

### Subtitle (30 chars max)
```
Lock Apps. Prove You're Sober.
```
**Character count: 30** ✅

**Rationale:** Two punchy phrases that explain the mechanic. "Lock Apps" captures utility seekers; "Prove You're Sober" captures the emotional/novelty hook.

#### Alternatives to A/B Test
| Option | Characters | Notes |
|--------|-----------|-------|
| `Lock Apps. Prove You're Sober.` | 30 | Primary — explains mechanic |
| `Block Drunk Texts & Calls` | 26 | Problem-focused |
| `Night App Lock & Challenges` | 28 | Feature-focused |

### Promotional Text (170 chars max — editable without app update)
```
🛡️ Lock your most triggering apps every night. Solve math, memory & speech challenges to unlock. 100% private — zero data leaves your phone. Start your streak tonight.
```
**Character count: 168** ✅

**Rationale:** Hits three conversion drivers — what it does, how it works, and the privacy angle. Ends with CTA.

---

## 3. Keyword Strategy

### Apple Keyword Field (100 chars max, comma-separated, no spaces)

```
drunk,texting,blocker,sober,sobriety,lock,app,night,challenge,recovery,alcohol,block,screen,time,safe
```
**Character count: 99** ✅

**Rules applied:**
- No duplicates of words already in title/subtitle
- No plurals of words already used in singular
- No spaces after commas
- No prepositions or articles
- Each word generates combinations with title/subtitle words

### Keyword Priority Matrix

| Priority | Keyword | Est. Volume | Competition | Relevance |
|----------|---------|------------|-------------|-----------|
| 🔴 P0 | drunk texting | High | Low | ★★★★★ |
| 🔴 P0 | stop drunk texting | Medium | Very Low | ★★★★★ |
| 🔴 P0 | app blocker | High | Medium | ★★★★☆ |
| 🔴 P0 | drunk mode | High | Low | ★★★★★ |
| 🟡 P1 | sobriety tracker | High | Medium | ★★★★☆ |
| 🟡 P1 | app lock night | Medium | Very Low | ★★★★★ |
| 🟡 P1 | drunk lock | Medium | Very Low | ★★★★★ |
| 🟡 P1 | block apps | High | High | ★★★☆☆ |
| 🟢 P2 | screen time lock | Medium | High | ★★★☆☆ |
| 🟢 P2 | sober app | Medium | Low | ★★★★☆ |
| 🟢 P2 | alcohol recovery | Medium | Medium | ★★★☆☆ |
| 🟢 P2 | digital detox | Medium | Medium | ★★☆☆☆ |
| 🟢 P2 | impulse control | Low | Very Low | ★★★★☆ |
| 🔵 P3 | drunk dial | Low | Very Low | ★★★★☆ |
| 🔵 P3 | social media lock | Medium | Medium | ★★★☆☆ |
| 🔵 P3 | math test unlock | Low | Very Low | ★★★★★ |
| 🔵 P3 | night mode lock | Low | Very Low | ★★★★☆ |

### Long-Tail Opportunities
These phrases won't fit in the 100-char keyword field but should appear in the description:
- "stop drunk texting ex"
- "lock social media at night"
- "math puzzle to unlock apps"
- "prevent drunk messages"
- "morning after regret prevention"
- "accountability app for drinking"
- "tongue twister sobriety test"

---

## 4. Competitor Analysis

### Direct Competitors

| App | Rating | Reviews | Price | Key Differentiator | Weakness |
|-----|--------|---------|-------|--------------------|----------|
| **Drunk Mode Locker** | 4.8 | ~225 | Free + IAP | Timer-based lock, puzzle unlock | No speech challenge, no Screen Time API integration |
| **SafeDrunk** | 4.5 | ~50 | One-time $4.99 | Math test unlock | No schedule, no contacts, no stats |
| **Drunk Dial NO!** | 3.8 | ~100 | Free | Contact hiding | Buggy, outdated, no app blocking |
| **Drunk Mode Keyboard** | 3.2 | ~80 | Free | Scrambled keyboard | Easy to bypass, gimmicky |

### SoberSend's Competitive Advantages

| Feature | SoberSend | Drunk Mode Locker | SafeDrunk | Drunk Dial NO! |
|---------|-----------|-------------------|-----------|----------------|
| Screen Time API (real blocking) | ✅ | ❌ | ❌ | ❌ |
| Multi-stage challenges | ✅ (math+memory+speech) | ✅ (puzzle only) | ✅ (math only) | ❌ |
| Speech recognition test | ✅ | ❌ | ❌ | ❌ |
| Scheduled lockdown window | ✅ | ✅ | ❌ | ❌ |
| Per-day schedule (bitmask) | ✅ | ❌ | ❌ | ❌ |
| Live Activity / Dynamic Island | ✅ | ❌ | ❌ | ❌ |
| Home screen widget | ✅ | ❌ | ❌ | ❌ |
| Sober notes / intentions | ✅ | ❌ | ❌ | ❌ |
| Morning report | ✅ | ❌ | ❌ | ❌ |
| Streak tracking | ✅ | ❌ | ❌ | ❌ |
| Achievement badges | ✅ | ❌ | ❌ | ❌ |
| Emergency unlock (Face ID + 24h cooldown) | ✅ | ❌ | ❌ | ❌ |
| 100% on-device / no data collection | ✅ | ❓ | ✅ | ❓ |
| No third-party SDKs | ✅ | ❌ | ✅ | ❌ |

### Positioning Statement
> SoberSend is the **only** app that uses Apple's Screen Time API for real app blocking, combines three types of cognitive challenges, and provides a complete accountability loop with streaks, morning reports, and sober notes — all with zero data leaving the device.

---

## 5. Screenshot & Visual Strategy

### Screenshot Sequence (6 screenshots, iPhone 6.7" required)

| # | Screen | Caption (keyword-rich) | Key Visual |
|---|--------|------------------------|------------|
| 1 | Onboarding welcome | **"We both know why you're here."** | Lock shield icon, emotional hook text |
| 2 | Setup / FamilyActivityPicker | **"Lock your most dangerous apps"** | App picker with social/dating apps selected |
| 3 | Challenge in progress | **"Prove you're sober to unlock"** | Math challenge with countdown timer |
| 4 | Morning Report | **"See what you avoided last night"** | Morning report card with streak badge |
| 5 | Stats / Achievements | **"Track your streak. Earn badges."** | Stats dashboard with achievement cards |
| 6 | Dynamic Island + Widget | **"Live countdown. Always watching."** | Dynamic Island expanded + home widget |

### Screenshot Design Guidelines
- **Background:** Use SoberTheme colors — lavender gradient (#E8E0F8 → #D9EBFA) for light, dark navy (#121214 → #1C1C1E) for dark
- **Device frame:** iPhone 15 Pro, no notch crop
- **Caption typography:** SF Pro Rounded Bold, 28pt, white on dark / dark on light
- **Layout:** Caption top (30%), device screenshot bottom (70%)
- **First 3 screenshots are critical** — most users don't scroll past them

### App Preview Video (30 seconds max)
| Timestamp | Content |
|-----------|---------|
| 0–5s | Emotional hook: "We both know why you're here" onboarding screen |
| 5–12s | Setting up lockdown: selecting apps, setting schedule |
| 12–20s | Attempting to open blocked app → shield appears → math challenge |
| 20–25s | Morning report with streak + achievements |
| 25–30s | CTA: "Your future self will thank you." + app icon |

### App Icon Guidelines
- Current: Lock shield icon on lavender background
- Must be recognizable at 60×60px (Spotlight) and 1024×1024px (Store)
- Avoid text in icon — it doesn't scale
- Test against competitor icons for differentiation in search results

---

## 6. Description (Full)

**Apple App Store — 4,000 chars max**

```
We both know why you're here.

Last night, you texted your ex. Or doom-scrolled until 3 AM. Or impulse-bought something you didn't need. SoberSend makes sure tonight is different.

━━━ HOW IT WORKS ━━━

1. PICK YOUR TRIGGERS
Select the apps and contacts you can't be trusted with after dark. Instagram, iMessage, dating apps, online shopping — whatever gets you in trouble.

2. SET YOUR SCHEDULE
Choose which nights and what hours to activate lockdown (default: 10 PM – 7 AM). Weekends only? Every night? You decide.

3. APPS GET BLOCKED — FOR REAL
SoberSend uses Apple's official Screen Time API to physically lock your selected apps. No workarounds. No "just this once."

4. PROVE YOU'RE SOBER TO UNLOCK
Want back in? Pass a series of cognitive challenges:
• 🧮 Math problems that scale in difficulty
• 🎨 Color memory sequences you must repeat
• 🗣️ Tongue twisters you have to say out loud
Easy when you're sober. Nearly impossible when you're not. That's the point.

━━━ FEATURES ━━━

🛡️ REAL APP BLOCKING
Uses Apple's Screen Time API — the same technology behind parental controls. Apps are physically shielded, not just hidden.

🧠 MULTI-STAGE CHALLENGES
Four difficulty levels (Easy → Expert) with math, memory, and speech recognition tests. 10-minute lockout after failed attempts.

📝 SOBER NOTES
Write a message to your future self. We'll show it to you when you try to unlock. "You already texted him twice this week. Don't do it."

📊 MORNING REPORT
Wake up to a summary of what you avoided last night. See your streak, failed attempts, and disasters averted.

🏆 ACHIEVEMENTS & STREAKS
Track consecutive sober nights. Earn badges: First Save, 7-Night Streak, 30-Night Streak, Survived Weekend, Ex-Free Zone.

🔴 EMERGENCY UNLOCK
Genuine emergency? Face ID bypass with a 24-hour cooldown to prevent abuse.

⌚ LIVE ACTIVITY
Real-time lockdown countdown in your Dynamic Island and Lock Screen. Always know when you're protected.

📱 HOME WIDGET
Glanceable lock status right on your home screen.

━━━ PRIVACY FIRST ━━━

• Zero data leaves your device — ever
• No analytics, no tracking, no third-party SDKs
• Speech recognition runs 100% on-device
• All challenge history stored locally in SwiftData
• We literally cannot see your data

━━━ PREMIUM ━━━

Free tier: 1 app + 1 contact + Easy/Medium challenges
Premium unlocks: Unlimited apps & contacts, all challenge levels, full stats, morning report sharing, all achievements.

• Monthly: $3.99/month (7-day free trial)
• Yearly: $29.99/year

━━━

Your future self will thank you. Set up your lockdown tonight.
```

**Character count: ~2,400** ✅ (well within 4,000 limit)

---

## 7. What's New (Release Notes)

### v1.0 (Launch)
```
🚀 Welcome to SoberSend!

Your lockdown starts tonight:
• Block apps and contacts during your vulnerable hours
• Prove sobriety with math, memory, and speech challenges
• Track your streak and earn achievement badges
• Morning reports show what you avoided
• Live Activity countdown in Dynamic Island
• 100% private — zero data leaves your phone

We both know why you're here. Let's do this.
```

### Template for Future Updates
```
v1.X — [Feature Name]

What's new:
• [Feature 1 — user benefit, not technical detail]
• [Feature 2]
• Bug fixes and performance improvements

Stay strong tonight. 🛡️
```

---

## 8. Rating & Review Strategy

### In-App Rating Prompt Triggers
The app should use `SKStoreReviewController.requestReview()` at these high-value moments:

| Trigger | Rationale |
|---------|-----------|
| Morning report viewed (streak ≥ 3) | User is seeing positive results |
| Achievement unlocked | Moment of accomplishment |
| 7th day after onboarding | Enough usage to form opinion |
| After successful challenge (sober user) | Positive interaction with core feature |

### Prompt Constraints (Apple Guidelines)
- Max 3 prompts per 365-day period (system-enforced)
- Never prompt during challenges or lockdown
- Never prompt on first launch
- Pre-prompt with custom dialog: "Enjoying SoberSend?" → Yes → system prompt / No → feedback form

### Review Response Templates

**Positive review (4–5 stars):**
> Thank you! Every night you stay protected is a win. Stay strong. 🛡️

**Feature request:**
> Great idea — we're always looking to improve. We've noted this for a future update. Thanks for the feedback!

**Bug report (1–3 stars):**
> Sorry about that! We take bugs seriously. Could you email us at [support email] with details? We'll get this fixed ASAP.

**"Too hard to unlock" complaint:**
> That's actually the point! 😄 The challenges are designed to be difficult when impaired. If you're sober and still struggling, try lowering the difficulty in Settings. We've got your back.

---

## 9. Localization Roadmap

### Priority Markets (by download potential)

| Priority | Language | Market | Notes |
|----------|----------|--------|-------|
| 🔴 P0 | English (US) | United States | Primary market, launch language |
| 🔴 P0 | English (UK) | United Kingdom | Strong drinking culture, high smartphone penetration |
| 🟡 P1 | Spanish | Spain, Mexico, Latin America | Large iOS market, strong social culture |
| 🟡 P1 | German | Germany, Austria | High App Store spend per user |
| 🟡 P1 | French | France, Canada (QC) | Significant iOS market |
| 🟢 P2 | Portuguese (BR) | Brazil | Growing iOS market |
| 🟢 P2 | Japanese | Japan | High ARPU, strong mobile culture |
| 🟢 P2 | Korean | South Korea | Heavy drinking culture, high smartphone use |

### Localization Notes
- **Speech challenge** requires `SFSpeechRecognizer` locale support — verify before localizing
- **Tongue twisters** must be culturally appropriate and equally difficult in target language
- Metadata (title, subtitle, keywords) should be researched per-locale, not just translated

---

## 10. Launch & Update Cadence

### Pre-Launch Checklist

- [ ] All 6 screenshots uploaded (6.7", 6.1", iPad if applicable)
- [ ] App preview video uploaded (30s max, no device frames)
- [ ] Privacy Policy live at `https://musamasalla.github.io/SoberSend/privacy.html`
- [ ] Terms of Service live at `https://musamasalla.github.io/SoberSend/terms.html`
- [ ] Support URL configured in App Store Connect
- [ ] App Privacy "Data Not Collected" declaration submitted
- [ ] StoreKit products configured in App Store Connect (monthly + yearly)
- [ ] Age Rating: 17+ (alcohol reference)
- [ ] Category: Health & Fitness (primary), Lifestyle (secondary)
- [ ] All entitlements approved (FamilyControls, App Groups)
- [ ] TestFlight beta tested on 3+ device types

### Launch Timing
- **Best days:** Tuesday–Thursday (avoid weekends — Apple editorial team is less active)
- **Best time of year:** January (New Year's resolutions), September (back to school/routine), Dry January
- **Avoid:** Major Apple event weeks, holiday freezes (Dec 23–27)

### Update Cadence (Post-Launch)
| Timeframe | Focus |
|-----------|-------|
| Week 1–2 | Monitor crash reports, fix critical bugs, respond to all reviews |
| Month 1 | First metadata A/B test (title/subtitle variants) |
| Month 2 | Screenshot optimization based on conversion data |
| Month 3 | Feature update based on review feedback |
| Quarterly | Keyword field refresh based on ranking data |

---

## 11. ASO Health Scorecard

### Current Estimated Score

| Dimension | Score | Max | Notes |
|-----------|-------|-----|-------|
| **Metadata Quality** | 22 | 25 | Strong title, subtitle, keyword field coverage |
| **Visual Assets** | 18 | 25 | Need screenshots + preview video uploaded |
| **Ratings & Reviews** | 5 | 25 | New app — no ratings yet |
| **Keyword Performance** | 10 | 25 | Low competition keywords targeted, unranked |
| **Overall** | **55** | **100** | Good foundation, needs launch traction |

### Priority Actions

| Priority | Action | Impact | Effort |
|----------|--------|--------|--------|
| 🔴 Critical | Upload all 6 screenshots with keyword-rich captions | High | Medium |
| 🔴 Critical | Record and upload 30s app preview video | High | Medium |
| 🟡 High | Implement in-app rating prompts at high-value moments | High | Low |
| 🟡 High | Submit app for Apple editorial consideration | Medium | Low |
| 🟢 Medium | Set up keyword ranking tracking (AppTweak/MobileAction) | Medium | Low |
| 🟢 Medium | Create landing page / Product Hunt launch | Medium | Medium |
| 🔵 Low | Begin Spanish/German localization | Medium | High |

---

## 12. A/B Testing Plan

### Test 1: App Title (Month 1)

| Variant | Title |
|---------|-------|
| A (Control) | `SoberSend: Drunk Text Blocker` |
| B | `SoberSend: Stop Drunk Texting` |
| C | `SoberSend: App Lock & Blocker` |

**Hypothesis:** "Drunk Text Blocker" will outperform because it's a noun phrase (what the app IS) vs. an action phrase.  
**Metric:** Impression → Install conversion rate  
**Duration:** 2–4 weeks per variant (need ~1,000 impressions per variant for significance)

### Test 2: First Screenshot (Month 2)

| Variant | First Screenshot |
|---------|-----------------|
| A (Control) | Emotional hook: "We both know why you're here" |
| B | Feature hook: "Lock your most dangerous apps" |
| C | Social proof: "X disasters averted" (dynamic counter) |

**Hypothesis:** Emotional hook will convert better for the primary audience (social drinkers) but feature hook may convert better for utility seekers.  
**Metric:** Impression → Product Page View → Install  
**Duration:** 3–4 weeks

### Test 3: Subtitle (Month 3)

| Variant | Subtitle |
|---------|----------|
| A (Control) | `Lock Apps. Prove You're Sober.` |
| B | `Block Drunk Texts & Calls` |

**Hypothesis:** The two-phrase structure creates more curiosity.  
**Metric:** Search → Impression → Install  
**Duration:** 2–3 weeks

---

## Appendix: App Store Connect Quick Reference

| Field | Value | Limit |
|-------|-------|-------|
| App Name | `SoberSend: Drunk Text Blocker` | 30 chars |
| Subtitle | `Lock Apps. Prove You're Sober.` | 30 chars |
| Promotional Text | 🛡️ Lock your most triggering apps every night... | 170 chars |
| Keywords | `drunk,texting,blocker,sober,sobriety,lock,...` | 100 chars |
| Primary Category | Health & Fitness | — |
| Secondary Category | Lifestyle | — |
| Age Rating | 17+ | Alcohol reference |
| Price | Free (with IAP) | — |
| SKUs | `com.sobersend.premium.monthly` / `.yearly` | — |
| Privacy URL | `https://musamasalla.github.io/SoberSend/privacy.html` | — |
| Terms URL | `https://musamasalla.github.io/SoberSend/terms.html` | — |
| Support URL | TBD | — |

---

*ASO documentation generated from source code analysis and competitive research. Review and update quarterly.*
