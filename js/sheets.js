/* ============================================================
   hiConstitution.com — Google Sheets Integration
   ============================================================
   HOW IT WORKS
   ────────────
   1. Admin enters a "Published CSV" URL for each data source
      (File → Share → Publish to web → CSV format)
   2. URLs are saved to localStorage so they persist across sessions
   3. On page load, each module checks localStorage for a sheet URL
      BEFORE falling back to the local JSON file
   4. Admin can also manually trigger an import to preview & download

   STORAGE KEYS
   ─────────────
   hiconst_sheet_quiz      → quiz data sheet URL
   hiconst_sheet_news      → news/articles sheet URL
   hiconst_sheet_judgments → judgments sheet URL
   hiconst_sheet_articles  → constitution articles sheet URL

   SHEET COLUMN FORMATS  (see admin panel for templates)
   ══════════════════════════════════════════════════════ */

'use strict';

var HiConstSheets = (function () {

  /* ── Storage helpers ── */
  var KEYS = {
    quiz:      'hiconst_sheet_quiz',
    news:      'hiconst_sheet_news',
    judgments: 'hiconst_sheet_judgments',
    articles:  'hiconst_sheet_articles',
  };

  function getUrl(type)        { return localStorage.getItem(KEYS[type]) || ''; }
  function setUrl(type, url)   { localStorage.setItem(KEYS[type], url.trim()); }
  function clearUrl(type)      { localStorage.removeItem(KEYS[type]); }
  function hasUrl(type)        { return !!getUrl(type); }

  /* ── Convert a Google Sheets URL to a fetchable CSV URL ──
     Accepts:
       • Full edit URL:  https://docs.google.com/spreadsheets/d/ID/edit#gid=0
       • Published URL:  https://docs.google.com/spreadsheets/d/ID/pub?...
       • Already a CSV export URL
     Returns the gviz CSV export URL for the first/specified sheet.
  ── */
  function toCsvUrl(raw) {
    raw = (raw || '').trim();
    if (!raw) return null;

    // Already a direct CSV export — return as-is
    if (raw.includes('/export?format=csv') || raw.includes('tqx=out:csv')) return raw;

    // Extract spreadsheet ID
    var idMatch = raw.match(/\/spreadsheets\/d\/([a-zA-Z0-9_-]+)/);
    if (!idMatch) return null;
    var id = idMatch[1];

    // Extract gid (sheet tab ID) if present
    var gidMatch = raw.match(/[#&?]gid=(\d+)/);
    var gid = gidMatch ? gidMatch[1] : '0';

    return 'https://docs.google.com/spreadsheets/d/' + id +
           '/gviz/tq?tqx=out:csv&gid=' + gid;
  }

  /* ── Robust CSV parser ──
     Handles: quoted fields, commas inside quotes, escaped quotes ("")
  ── */
  function parseCsv(text) {
    var rows = [];
    var row  = [];
    var field = '';
    var inQ   = false;
    var i = 0;

    // Normalise line endings
    text = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    while (i < text.length) {
      var ch = text[i];
      if (inQ) {
        if (ch === '"') {
          if (text[i + 1] === '"') { field += '"'; i += 2; continue; } // escaped quote
          inQ = false;
        } else {
          field += ch;
        }
      } else {
        if (ch === '"') {
          inQ = true;
        } else if (ch === ',') {
          row.push(field.trim());
          field = '';
        } else if (ch === '\n') {
          row.push(field.trim());
          if (row.some(function(c){ return c !== ''; })) rows.push(row);
          row = []; field = '';
        } else {
          field += ch;
        }
      }
      i++;
    }
    // Last field / row
    row.push(field.trim());
    if (row.some(function(c){ return c !== ''; })) rows.push(row);

    return rows;
  }

  /* ── Fetch CSV from a sheet URL ── */
  function fetchCsv(url) {
    return fetch(url, { cache: 'no-cache' })
      .then(function(res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.text();
      })
      .then(parseCsv);
  }

  /* ══════════════════════════════════════════════════════════
     PARSERS — convert flat CSV rows into the app's JSON format
  ══════════════════════════════════════════════════════════ */

  /* QUIZ SHEET columns (row 1 = header, skip it):
     category_id | category_title | category_icon | category_description |
     category_order | category_difficulty | quiz_id | quiz_title |
     quiz_difficulty | question | option_a | option_b | option_c | option_d |
     correct_index (0-based) | explanation
  */
  function parseQuizCsv(rows) {
    if (rows.length < 2) throw new Error('Sheet has no data rows');
    var header = rows[0].map(function(h){ return h.toLowerCase().replace(/\s+/g,'_'); });

    function col(row, name) {
      var idx = header.indexOf(name);
      return idx >= 0 ? (row[idx] || '') : '';
    }

    var catMap = {};
    var catOrder = [];

    rows.slice(1).forEach(function(row) {
      if (!row.length || !row.some(function(c){ return c; })) return;

      var catId = col(row, 'category_id') || col(row, 'category');
      if (!catId) return;

      if (!catMap[catId]) {
        catMap[catId] = {
          id:          catId,
          title:       col(row, 'category_title')       || catId,
          icon:        col(row, 'category_icon')        || '📚',
          description: col(row, 'category_description') || '',
          order:       parseInt(col(row, 'category_order')) || 99,
          difficulty:  col(row, 'category_difficulty')  || 'mixed',
          quizzes:     [],
          _quizMap:    {}
        };
        catOrder.push(catId);
      }
      var cat = catMap[catId];

      var qzId = col(row, 'quiz_id') || col(row, 'quiz');
      if (!qzId) return;

      if (!cat._quizMap[qzId]) {
        var qzObj = {
          id:         qzId,
          title:      col(row, 'quiz_title')      || qzId,
          difficulty: col(row, 'quiz_difficulty') || 'medium',
          questions:  []
        };
        cat._quizMap[qzId] = qzObj;
        cat.quizzes.push(qzObj);
      }
      var quiz = cat._quizMap[qzId];

      var q = col(row, 'question');
      if (!q) return;

      var opts = [
        col(row, 'option_a') || col(row, 'option_1'),
        col(row, 'option_b') || col(row, 'option_2'),
        col(row, 'option_c') || col(row, 'option_3'),
        col(row, 'option_d') || col(row, 'option_4')
      ].filter(Boolean);

      var ansRaw    = col(row, 'correct_index') || col(row, 'answer') || col(row, 'correct');
      var ansIdx    = parseInt(ansRaw);
      if (isNaN(ansIdx)) {
        // Try letter: A=0, B=1, ...
        ansIdx = ansRaw.trim().toUpperCase().charCodeAt(0) - 65;
      }
      if (isNaN(ansIdx) || ansIdx < 0) ansIdx = 0;

      quiz.questions.push({
        q:           q,
        options:     opts,
        answer:      ansIdx,
        explanation: col(row, 'explanation') || col(row, 'explain') || ''
      });
    });

    // Clean up helper map
    return catOrder.map(function(id){
      var c = catMap[id];
      delete c._quizMap;
      return c;
    });
  }

  /* NEWS SHEET columns:
     id | title | date (YYYY-MM-DD) | category | excerpt | content |
     source | source_url | tags (comma-separated)
  */
  function parseNewsCsv(rows) {
    if (rows.length < 2) throw new Error('No data rows');
    var header = rows[0].map(function(h){ return h.toLowerCase().replace(/\s+/g,'_'); });
    function col(row, name) { var i = header.indexOf(name); return i >= 0 ? (row[i] || '') : ''; }

    return rows.slice(1).filter(function(r){ return r.some(Boolean); }).map(function(row) {
      var title  = col(row, 'title');
      var id     = col(row, 'id') || title.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'').substring(0,60) + '-' + (col(row,'date') || '').split('-')[0];
      return {
        id:        id,
        title:     title,
        date:      col(row, 'date'),
        category:  col(row, 'category') || 'news',
        excerpt:   col(row, 'excerpt'),
        content:   col(row, 'content').replace(/\\n/g, '\n'),
        source:    col(row, 'source') || col(row, 'source_name'),
        sourceUrl: col(row, 'source_url') || col(row, 'sourceurl') || '',
        tags:      (col(row, 'tags') || '').split(',').map(function(t){ return t.trim(); }).filter(Boolean)
      };
    });
  }

  /* JUDGMENTS SHEET columns:
     id | year | case_name | court | summary | significance | articles
  */
  function parseJudgmentsCsv(rows) {
    if (rows.length < 2) throw new Error('No data rows');
    var header = rows[0].map(function(h){ return h.toLowerCase().replace(/\s+/g,'_'); });
    function col(row, name) { var i = header.indexOf(name); return i >= 0 ? (row[i] || '') : ''; }

    return rows.slice(1).filter(function(r){ return r.some(Boolean); }).map(function(row) {
      return {
        id:           col(row,'id') || col(row,'case_id'),
        year:         col(row,'year'),
        case:         col(row,'case_name') || col(row,'case'),
        court:        col(row,'court') || 'Supreme Court of India',
        summary:      col(row,'summary'),
        significance: col(row,'significance') || col(row,'importance'),
        articles:     (col(row,'articles') || '').split(',').map(function(a){ return a.trim(); }).filter(Boolean)
      };
    });
  }

  /* ══════════════════════════════════════════════════════════
     PUBLIC API
  ══════════════════════════════════════════════════════════ */

  /* Fetch + parse quiz data from the configured sheet.
     Returns a Promise<Array> of category objects.
     Rejects if no URL configured or fetch/parse fails.  */
  function fetchQuiz() {
    var url = toCsvUrl(getUrl('quiz'));
    if (!url) return Promise.reject(new Error('No sheet URL configured'));
    return fetchCsv(url).then(parseQuizCsv);
  }

  function fetchNews() {
    var url = toCsvUrl(getUrl('news'));
    if (!url) return Promise.reject(new Error('No sheet URL configured'));
    return fetchCsv(url).then(parseNewsCsv);
  }

  function fetchJudgments() {
    var url = toCsvUrl(getUrl('judgments'));
    if (!url) return Promise.reject(new Error('No sheet URL configured'));
    return fetchCsv(url).then(parseJudgmentsCsv);
  }

  return {
    KEYS:             KEYS,
    getUrl:           getUrl,
    setUrl:           setUrl,
    clearUrl:         clearUrl,
    hasUrl:           hasUrl,
    toCsvUrl:         toCsvUrl,
    parseCsv:         parseCsv,
    parseQuizCsv:     parseQuizCsv,
    parseNewsCsv:     parseNewsCsv,
    parseJudgmentsCsv:parseJudgmentsCsv,
    fetchCsv:         fetchCsv,
    fetchQuiz:        fetchQuiz,
    fetchNews:        fetchNews,
    fetchJudgments:   fetchJudgments,
  };

})();
