# hiCONSTITUTION — Setup & Deployment Guide

## Prerequisites

- **Git** — verify with `git --version`
- **VS Code** with the [Live Server extension](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) **OR** Python 3 installed
- **Cloudflare account** with the domain `hiconstitution.com` already added

---

## Run locally

**Option A — VS Code Live Server**
Right-click `index.html` in the VS Code Explorer → **Open with Live Server**

**Option B — Python**
```bash
python -m http.server 3000
```
Then open http://localhost:3000 in your browser.

---

## Git setup (first time only)

```bash
git init
git remote add origin YOUR_GITHUB_REPO_URL
```

---

## Commit and push

```bash
git add .
git commit -m "Your commit message"
git push origin main
```

---

## Cloudflare Pages deployment

Two options:

1. **Auto-deploy via GitHub** (recommended)
   - Go to Cloudflare dashboard → **Pages** → **Create a project** → **Connect to Git**
   - Select your GitHub repo and set branch to `main`
   - Build settings: leave blank (static site, no build command needed)
   - Every `git push` to `main` will auto-deploy

2. **Direct upload**
   - Go to Cloudflare dashboard → **Pages** → **Create a project** → **Direct Upload**
   - Drag and drop the project folder or zip file

---

## HTTPS & www redirect

In the Cloudflare dashboard:

- **SSL/TLS** → **Overview** → set mode to **Full** or **Full (strict)**
- **SSL/TLS** → **Edge Certificates** → **Always Use HTTPS** → toggle **ON**
- The `_redirects` file in this repo already handles `www.hiconstitution.com` → `hiconstitution.com`

---

## Admin panel

Open `admin.html` in your browser to add or edit content. The admin panel writes directly to the JSON data files in the `data/` folder.

> Keep `admin.html` private — do not share the URL publicly.

---

## Adding news / articles

Edit `data/articles.json` (or the relevant JSON file) to add new entries. Use this format:

```json
{
  "id": "unique-id",
  "title": "Article title",
  "date": "2026-04-13",
  "category": "judgment",
  "excerpt": "Short 2-3 sentence preview shown on listing pages.",
  "content": "Full article content goes here.",
  "source": "Source name"
}
```

---

## File structure overview

```
index.html                    — Homepage
read-the-constitution.html    — Browse articles by part/chapter
library-article.html          — Read individual articles
Constitutional-amendments.html — All 106 constitutional amendments
landmark-judgments.html       — Landmark Supreme Court judgments
making.html                   — History of the Constitution's making
timeline.html                 — Constitutional timeline
facts.html                    — Interesting constitutional facts
facts-about-indian-constitution.html — Interesting constitutional facts
quiz.html                     — Practice quizzes
draft-Constitution-of-India.html — 1948 Draft Constitution
admin.html                    — Content admin panel (keep private)

css/style.css                 — Main stylesheet
js/                           — JavaScript files
data/                         — JSON data files (articles, judgments, etc.)

_headers                      — Cloudflare Pages security & cache headers
_redirects                    — Cloudflare Pages URL redirects
robots.txt                    — Search engine crawl rules
sitemap.xml                   — Sitemap for SEO
```
