#!/usr/bin/env python3
"""
inject_seo.py — Injects SEO tags into hiConstitution HTML files.
Run from: C:/Users/epicb/Downloads/hiCONSTITUTION/hiCONSTITUTION/
"""

import os
import re
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOMAIN = 'https://hiconstitution.com'
OG_IMAGE = 'https://hiconstitution.com/og-image.jpg'

pages = {
    'index.html': {
        'title': 'hiConstitution — Learn the Indian Constitution',
        'desc': "Explore, understand, and master the Constitution of India. Read every Article, browse landmark judgments, take quizzes, and study the making of India's founding document.",
        'url': f'{DOMAIN}/',
        'type': 'website',
        'schema': 'WebSite',
        'noindex': False,
    },
    'read-the-constitution.html': {
        'title': 'Read the Constitution of India — All Parts & Schedules | hiConstitution',
        'desc': 'Read the full text of the Indian Constitution — all 22 Parts, 12 Schedules, and 448 Articles — with simplified explanations and Hindi translation.',
        'url': f'{DOMAIN}/read-the-constitution.html',
        'type': 'website',
        'schema': 'WebPage',
        'noindex': False,
    },
    'amendments.html': {
        'title': 'All 106 Constitutional Amendments of India | hiConstitution',
        'desc': "Explore all 106 Constitutional Amendments of India. Understand what changed, when, and why — from the 1st Amendment in 1951 to the 106th Women's Reservation Act in 2023.",
        'url': f'{DOMAIN}/amendments.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'judgments.html': {
        'title': 'Landmark Supreme Court Judgments on the Indian Constitution | hiConstitution',
        'desc': "Study landmark Supreme Court judgments that shaped India's Constitution — Kesavananda Bharati, Maneka Gandhi, Vishaka, and more.",
        'url': f'{DOMAIN}/judgments.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'making.html': {
        'title': "Making of India's Constitution — Constituent Assembly History | hiConstitution",
        'desc': "Discover how India's Constitution was made. Explore the Constituent Assembly sessions, key framers like Dr. Ambedkar, Nehru, and Patel, and the 2 year 11 month drafting process.",
        'url': f'{DOMAIN}/making.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'timeline.html': {
        'title': 'Constitutional Timeline of India — 1934 to 2023 | hiConstitution',
        'desc': "Explore the full chronological history of India's Constitution — from the first demand in 1934 to the Women's Reservation Act in 2023.",
        'url': f'{DOMAIN}/timeline.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'facts.html': {
        'title': 'Amazing Facts About the Indian Constitution | hiConstitution',
        'desc': "Discover 50+ fascinating facts about the Indian Constitution — the world's longest written constitution, its global borrowings, and the original hand-calligraphed document.",
        'url': f'{DOMAIN}/facts.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'quiz.html': {
        'title': 'Indian Constitution Quiz — UPSC & GK Practice | hiConstitution',
        'desc': 'Test your knowledge of the Indian Constitution with UPSC-level MCQs. Topic-wise quizzes on Fundamental Rights, Preamble, Amendments, Directive Principles, and more.',
        'url': f'{DOMAIN}/quiz.html',
        'type': 'website',
        'schema': 'WebPage',
        'noindex': False,
    },
    'draft.html': {
        'title': 'Draft Constitution of India 1948 — Original Draft Outline | hiConstitution',
        'desc': "Explore the 1948 Draft Constitution of India prepared by Dr. Ambedkar's Drafting Committee, with 395 Articles and 8 Schedules. Compare with the final adopted Constitution.",
        'url': f'{DOMAIN}/draft.html',
        'type': 'article',
        'schema': 'Article',
        'noindex': False,
    },
    'library-article.html': {
        'title': 'Article of the Indian Constitution | hiConstitution',
        'desc': 'Read the original text, simplified explanation, and Hindi translation of this Article of the Indian Constitution.',
        'url': f'{DOMAIN}/library-article.html',
        'type': 'article',
        'schema': 'Article',
        'dynamic': True,
        'noindex': False,
    },
    'part.html': {
        'title': 'Part of the Indian Constitution | hiConstitution',
        'desc': 'Read the articles and provisions of this Part of the Indian Constitution.',
        'url': f'{DOMAIN}/part.html',
        'type': 'article',
        'schema': 'WebPage',
        'dynamic': True,
        'noindex': False,
    },
    'schedule.html': {
        'title': 'Schedule of the Indian Constitution | hiConstitution',
        'desc': 'Read the complete details of this Schedule of the Indian Constitution.',
        'url': f'{DOMAIN}/schedule.html',
        'type': 'article',
        'schema': 'WebPage',
        'dynamic': True,
        'noindex': False,
    },
    'admin.html': {
        'title': 'Admin Panel — hiConstitution',
        'desc': 'Admin panel for content management.',
        'url': f'{DOMAIN}/admin.html',
        'type': 'website',
        'schema': 'WebPage',
        'noindex': True,
    },
}

# ----------------------------------------------------------------
# JSON-LD builders
# ----------------------------------------------------------------

def build_jsonld_website():
    return {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "WebSite",
                "@id": "https://hiconstitution.com/#website",
                "url": "https://hiconstitution.com/",
                "name": "hiConstitution",
                "description": "Learn the Indian Constitution — Articles, Amendments, Judgments, Timeline and Quizzes",
                "inLanguage": "en-IN",
                "potentialAction": {
                    "@type": "SearchAction",
                    "target": {
                        "@type": "EntryPoint",
                        "urlTemplate": "https://hiconstitution.com/read-the-constitution.html?q={search_term_string}"
                    },
                    "query-input": "required name=search_term_string"
                }
            },
            {
                "@type": "Organization",
                "@id": "https://hiconstitution.com/#organization",
                "name": "hiConstitution",
                "url": "https://hiconstitution.com/",
                "logo": {
                    "@type": "ImageObject",
                    "url": "https://hiconstitution.com/og-image.jpg"
                }
            }
        ]
    }


def build_jsonld_article(title, desc, url):
    return {
        "@context": "https://schema.org",
        "@type": "Article",
        "name": title,
        "description": desc,
        "url": url,
        "inLanguage": "en-IN",
        "publisher": {
            "@type": "Organization",
            "name": "hiConstitution",
            "url": "https://hiconstitution.com"
        },
        "isPartOf": {
            "@type": "WebSite",
            "@id": "https://hiconstitution.com/#website"
        }
    }


def build_jsonld_webpage(title, desc, url):
    return {
        "@context": "https://schema.org",
        "@type": "WebPage",
        "name": title,
        "description": desc,
        "url": url,
        "inLanguage": "en-IN",
        "isPartOf": {
            "@type": "WebSite",
            "@id": "https://hiconstitution.com/#website"
        }
    }


def get_jsonld(filename, meta):
    schema = meta['schema']
    if schema == 'WebSite':
        return json.dumps(build_jsonld_website(), indent=2, ensure_ascii=False)
    elif schema == 'Article':
        return json.dumps(build_jsonld_article(meta['title'], meta['desc'], meta['url']), indent=2, ensure_ascii=False)
    else:
        return json.dumps(build_jsonld_webpage(meta['title'], meta['desc'], meta['url']), indent=2, ensure_ascii=False)


# ----------------------------------------------------------------
# SEO block builder
# ----------------------------------------------------------------

def build_seo_block(filename, meta):
    robots_value = "noindex, nofollow" if meta.get('noindex') else "index, follow"
    jsonld = get_jsonld(filename, meta)
    # Indent the JSON-LD by 2 spaces for readability
    jsonld_indented = '\n'.join('  ' + line for line in jsonld.splitlines())

    block = f"""
  <!-- SEO BLOCK -->

  <!-- HTTPS Redirect (client-side fallback) -->
  <script>if(location.protocol==='http:'&&location.hostname!=='localhost'&&location.hostname!=='127.0.0.1')location.replace('https://'+location.host+location.pathname+location.search+location.hash);</script>

  <!-- Favicons -->
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <link rel="icon" type="image/x-icon" href="/favicon.ico" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  <meta name="theme-color" content="#1A237E" />
  <meta name="msapplication-TileColor" content="#1A237E" />

  <!-- Canonical & Robots -->
  <link rel="canonical" href="{meta['url']}" />
  <meta name="robots" content="{robots_value}" />
  <meta name="author" content="hiConstitution" />

  <!-- Open Graph -->
  <meta property="og:type" content="{meta['type']}" />
  <meta property="og:site_name" content="hiConstitution" />
  <meta property="og:title" content="{meta['title']}" />
  <meta property="og:description" content="{meta['desc']}" />
  <meta property="og:url" content="{meta['url']}" />
  <meta property="og:image" content="{OG_IMAGE}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:locale" content="en_IN" />

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="{meta['title']}" />
  <meta name="twitter:description" content="{meta['desc']}" />
  <meta name="twitter:image" content="{OG_IMAGE}" />

  <!-- JSON-LD Structured Data -->
  <script type="application/ld+json">
{jsonld_indented}
  </script>
"""
    return block


# ----------------------------------------------------------------
# HTML processing
# ----------------------------------------------------------------

def process_file(filename, meta):
    filepath = os.path.join(BASE_DIR, filename)
    if not os.path.exists(filepath):
        print(f"  SKIP (not found): {filename}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if already injected
    if '<!-- SEO BLOCK -->' in content:
        print(f"  SKIP (already injected): {filename}")
        return

    modified = content

    # 1. Update <title>
    old_title_match = re.search(r'<title>(.*?)</title>', modified, re.IGNORECASE | re.DOTALL)
    if old_title_match:
        old_title = old_title_match.group(1).strip()
        new_title = meta['title']
        if old_title != new_title:
            modified = re.sub(r'<title>.*?</title>', f'<title>{new_title}</title>',
                              modified, flags=re.IGNORECASE | re.DOTALL)
            print(f"  Title updated: '{old_title}' -> '{new_title}'")
        else:
            print(f"  Title unchanged: '{old_title}'")
    else:
        print(f"  WARNING: No <title> found in {filename}")

    # 2. Update existing <meta name="description">
    desc_pattern = re.compile(
        r'<meta\s+name=["\']description["\']\s+content=["\'].*?["\']\s*/?>',
        re.IGNORECASE | re.DOTALL
    )
    if desc_pattern.search(modified):
        modified = desc_pattern.sub(
            f'<meta name="description" content="{meta["desc"]}" />',
            modified
        )
        print(f"  Description updated.")
    else:
        print(f"  WARNING: No existing <meta name=\"description\"> found in {filename}")

    # 3. Inject SEO block before </head>
    seo_block = build_seo_block(filename, meta)
    if '</head>' in modified:
        modified = modified.replace('</head>', seo_block + '</head>', 1)
        print(f"  SEO block injected.")
    else:
        print(f"  WARNING: No </head> tag found in {filename} — skipping injection.")
        return

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(modified)

    print(f"  DONE: {filename}")


# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------

if __name__ == '__main__':
    print("=" * 60)
    print("hiConstitution SEO Injection Script")
    print("=" * 60)

    for filename, meta in pages.items():
        print(f"\n[{filename}]")
        process_file(filename, meta)

    print("\n" + "=" * 60)
    print("Injection complete.")
    print("=" * 60)
