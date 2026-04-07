/* ============================================================
   hiConstitution.com — Quiz JS
   ============================================================
   CONTENT SOURCE: data/quiz.json
   (Managed directly from the Admin Panel)
   ============================================================ */

'use strict';

/* ── Load Quiz Data (CSV first, then hardcoded fallback) ── */
var QUIZ_CATEGORIES = [];

function initQuiz(categories) {
  QUIZ_CATEGORIES = categories.sort((a, b) => (parseInt(a.order) || 99) - (parseInt(b.order) || 99));
  renderCategories();
  initDailyChallenge();
  bindModalEvents();
  maybeAutoOpenTopic();
}

fetch('data/quiz.json')
  .then(function(res) {
    if (!res.ok) throw new Error('JSON not found');
    return res.json();
  })
  .then(function(data) {
    if (!data || data.length === 0) throw new Error('Empty JSON');
    initQuiz(data);
  })
  .catch(function() {
    // Fallback to hardcoded data
    initQuiz(QUIZ_CATEGORIES_HARDCODED);
  });

/* ── Hardcoded Fallback Data ── */
var QUIZ_CATEGORIES_HARDCODED = [
  {
    id: 'fundamental-rights',
    order: 1,
    icon: '⚖️',
    title: 'Fundamental Rights',
    description: 'Articles 12–35: rights guaranteed to every person in India.',
    quizzes: [
      {
        id: 'fr-basics',
        title: 'Level 1: Basics of Fundamental Rights',
        difficulty: 'medium',
        questions: [
          {
            q: 'Under which article of the Constitution is the Right to Equality guaranteed?',
            options: ['Article 12', 'Article 14', 'Article 19', 'Article 21'],
            answer: 1,
            explanation: 'Article 14 guarantees the right to equality before law and equal protection of laws. It applies to all persons, not just citizens.'
          }
        ]
      }
    ]
  },
  {
    id: 'preamble',
    order: 2,
    icon: '📜',
    title: 'Preamble',
    description: 'The introductory statement of the Constitution and its key values.',
    quizzes: [
      {
        id: 'preamble-test',
        title: 'Preamble Quick Test',
        difficulty: 'easy',
        questions: [
          {
            q: 'Which words were added to the Preamble by the 42nd Constitutional Amendment (1976)?',
            options: ['Democratic and Republic', 'Socialist and Secular', 'Justice and Fraternity', 'Sovereign and Integrity'],
            answer: 1,
            explanation: 'The 42nd Amendment (1976) added "Socialist," "Secular," and "Integrity" to the Preamble.'
          }
        ]
      }
    ]
  }
];

/* ── Quiz State ── */
var quizState = {
  category: null,
  quiz: null,
  questions: [],
  currentIndex: 0,
  score: 0,
  answered: false,
  results: []
};

/* ── DOM References ── */
var overlay = document.getElementById('quizModalOverlay');
var modal = document.getElementById('quizModal');
var quizContent = document.getElementById('quizContent');
var scoreScreen = document.getElementById('scoreScreen');

/* ── Open Quiz ── */
function openQuiz(categoryId, quizId) {
  var cat = QUIZ_CATEGORIES.find(c => c.id === categoryId);
  if (!cat) return;
  
  var qz = quizId ? (cat.quizzes || []).find(q => q.id === quizId) : (cat.quizzes && cat.quizzes.length > 0 ? cat.quizzes[0] : null);
  if (!qz) return;

  quizState.category = cat;
  quizState.quiz = qz;
  quizState.questions = shuffleArray((qz.questions || []).slice());
  quizState.currentIndex = 0;
  quizState.score = 0;
  quizState.answered = false;
  quizState.results = [];

  // Update modal header
  document.getElementById('quizCategoryName').textContent = qz.title;

  // Show content, hide score
  quizContent.style.display = '';
  scoreScreen.classList.remove('show');

  renderQuestion();

  overlay.classList.add('open');
  document.body.style.overflow = 'hidden';
}

/* ── Close Quiz ── */
function closeQuiz() {
  overlay.classList.remove('open');
  document.body.style.overflow = '';
}

/* ── Render Current Question ── */
function renderQuestion() {
  var q = quizState.questions[quizState.currentIndex];
  var total = quizState.questions.length;
  var current = quizState.currentIndex + 1;
  var pct = ((current - 1) / total * 100).toFixed(0);

  // Progress
  document.getElementById('qProgressLabel').textContent = 'Question ' + current + ' of ' + total;
  document.getElementById('qProgressScore').textContent = quizState.score + ' correct';
  document.getElementById('qProgressFill').style.width = pct + '%';

  // Question
  document.getElementById('qNumber').textContent = 'Question ' + current;
  document.getElementById('qText').textContent = q.q;

  // Options
  var optionsWrap = document.getElementById('qOptions');
  optionsWrap.innerHTML = '';
  var letters = ['A', 'B', 'C', 'D'];
  q.options.forEach(function (opt, idx) {
    var btn = document.createElement('button');
    btn.className = 'quiz-option';
    btn.setAttribute('data-index', idx);
    btn.innerHTML =
      '<span class="option-letter">' + letters[idx] + '</span>' +
      '<span class="option-text">' + escapeHtmlQuiz(opt) + '</span>';
    btn.addEventListener('click', function () { selectAnswer(idx); });
    optionsWrap.appendChild(btn);
  });

  // Hide explanation and next button
  var explanation = document.getElementById('qExplanation');
  explanation.classList.remove('show');
  explanation.querySelector('.quiz-explanation-text').textContent = '';

  var nextBtn = document.getElementById('btnNextQ');
  nextBtn.classList.remove('show');
  nextBtn.textContent = current === total ? 'See Results' : 'Next Question →';

  quizState.answered = false;
}

/* ── Select Answer ── */
function selectAnswer(selectedIdx) {
  if (quizState.answered) return;
  quizState.answered = true;

  var q = quizState.questions[quizState.currentIndex];
  var correct = q.answer;
  var isCorrect = selectedIdx === correct;

  if (isCorrect) {
    quizState.score++;
  }

  quizState.results.push({ correct: isCorrect, selectedIdx: selectedIdx, correctIdx: correct });

  // Style options
  var options = document.querySelectorAll('.quiz-option');
  options.forEach(function (btn) {
    btn.disabled = true;
    var idx = parseInt(btn.getAttribute('data-index'));
    if (idx === correct) {
      btn.classList.add('correct');
    } else if (idx === selectedIdx && !isCorrect) {
      btn.classList.add('incorrect');
    }
  });

  // Show explanation
  var explanation = document.getElementById('qExplanation');
  explanation.querySelector('.quiz-explanation-text').textContent = q.explanation;
  explanation.classList.add('show');

  // Show next button
  document.getElementById('btnNextQ').classList.add('show');
}

/* ── Next Question ── */
function nextQuestion() {
  var total = quizState.questions.length;
  if (quizState.currentIndex + 1 >= total) {
    showScore();
  } else {
    quizState.currentIndex++;
    renderQuestion();
  }
}

/* ── Show Score Screen ── */
function showScore() {
  quizContent.style.display = 'none';
  scoreScreen.classList.add('show');

  var total = quizState.questions.length;
  var score = quizState.score;
  var pct = Math.round((score / total) * 100);

  var circle = document.getElementById('scoreCircle');
  circle.className = 'score-circle';
  if (pct >= 80) circle.classList.add('excellent');
  else if (pct >= 50) circle.classList.add('good');
  else circle.classList.add('poor');

  document.getElementById('scorePct').textContent = pct + '%';
  document.getElementById('scoreCorrect').textContent = score;
  document.getElementById('scoreTotal').textContent = total;
  document.getElementById('scoreIncorrect').textContent = total - score;

  var msg, sub;
  if (pct === 100) { msg = '🏆 Perfect Score!'; sub = 'Outstanding! You have mastered this topic.'; }
  else if (pct >= 80) { msg = '🌟 Excellent!'; sub = 'Great knowledge of the Constitution!'; }
  else if (pct >= 60) { msg = '👍 Good Job!'; sub = 'Solid understanding. Keep studying!'; }
  else if (pct >= 40) { msg = '📖 Keep Practicing!'; sub = 'Review the articles and try again.'; }
  else { msg = '💪 Don\'t Give Up!'; sub = 'The Constitution has many nuances. Keep learning!'; }

  document.getElementById('scoreMsg').textContent = msg;
  document.getElementById('scoreSub').textContent = sub;

  // Save to local storage
  saveHighScore(quizState.quiz.id, score, total);
}

/* ── Save & Load High Scores ── */
function saveHighScore(quizId, score, total) {
  try {
    var key = 'hc_hs_' + quizId;
    var existing = JSON.parse(localStorage.getItem(key) || '0');
    var newScore = Math.max(parseInt(existing) || 0, score);
    localStorage.setItem(key, JSON.stringify(newScore));
  } catch (e) { /* localStorage unavailable */ }
}

function getHighScore(quizId) {
  try {
    return parseInt(JSON.parse(localStorage.getItem('hc_hs_' + quizId))) || 0;
  } catch (e) { return 0; }
}

/* ── Restart Quiz ── */
function restartQuiz() {
  openQuiz(quizState.category.id, quizState.quiz.id);
}

/* ── Utility: shuffle array ── */
function shuffleArray(arr) {
  for (var i = arr.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr;
}

function escapeHtmlQuiz(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ── Render Category Cards ── */
function renderCategories() {
  var grid = document.getElementById('categoriesGrid');
  if (!grid) return;
  grid.innerHTML = '';

  QUIZ_CATEGORIES.forEach(function (cat) {
    var quizCount = (cat.quizzes || []).length;
    var questionCount = (cat.quizzes || []).reduce((sum, qz) => sum + (qz.questions || []).length, 0);

    var card = document.createElement('div');
    card.className = 'category-card';
    card.style.borderTop = "3px solid var(--navy)";
    card.setAttribute('tabindex', '0');
    card.setAttribute('role', 'button');

    card.innerHTML =
      '<div class="category-icon">' + (cat.icon || '📚') + '</div>' +
      '<div class="category-title">' + escapeHtmlQuiz(cat.title) + '</div>' +
      '<p style="font-size:0.82rem;color:var(--muted);line-height:1.5;margin-top:4px;">' + escapeHtmlQuiz(cat.description || '') + '</p>' +
      '<div class="category-meta">' +
        '<span class="q-count" style="font-weight:600; color:var(--navy);">' + quizCount + ' Quizzes • ' + questionCount + ' Qs</span>' +
      '</div>';

    card.addEventListener('click', function () { openCategoryView(cat.id); });
    card.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openCategoryView(cat.id); }
    });

    grid.appendChild(card);
  });
}

function openCategoryView(categoryId) {
  var cat = QUIZ_CATEGORIES.find(c => c.id === categoryId);
  if (!cat) return;

  document.getElementById('mainCategoriesSection').classList.add('hidden');
  document.getElementById('quizListSection').classList.remove('hidden');
  
  document.getElementById('subCatLabel').textContent = (cat.icon || '') + " " + cat.title;
  document.getElementById('subCatDesc').textContent = cat.description;

  var grid = document.getElementById('quizzesGrid');
  if (!grid) return;
  grid.innerHTML = '';

  (cat.quizzes || []).forEach(function (qz) {
    var hs = getHighScore(qz.id);
    var card = document.createElement('div');
    card.className = 'category-card';
    card.setAttribute('data-difficulty', qz.difficulty || 'medium');
    
    var diffLabel = (qz.difficulty || 'medium').charAt(0).toUpperCase() + (qz.difficulty || 'medium').slice(1);
    var diffClass = 'diff-' + (qz.difficulty || 'medium');

    card.innerHTML =
      '<div class="category-title" style="margin-top:10px;">' + escapeHtmlQuiz(qz.title) + '</div>' +
      '<div class="category-meta" style="margin-top:20px;">' +
        '<span class="q-count">' + (qz.questions || []).length + ' Qs' + (hs > 0 ? ' · Best: ' + hs : '') + '</span>' +
        '<span class="difficulty-pill ' + diffClass + '">' + diffLabel + '</span>' +
      '</div>';

    card.addEventListener('click', function () { openQuiz(cat.id, qz.id); });
    grid.appendChild(card);
  });
}

function showCategoriesView() {
  var qList = document.getElementById('quizListSection');
  var mCat = document.getElementById('mainCategoriesSection');
  if(qList) qList.classList.add('hidden');
  if(mCat) mCat.classList.remove('hidden');
}

/* ── Daily Challenge ── */
function initDailyChallenge() {
  var btn = document.getElementById('btnDailyChallenge');
  if (!btn) return;
  btn.addEventListener('click', function () {
    var now = new Date();
    var start = new Date(now.getFullYear(), 0, 0);
    var diff = now - start;
    var oneDay = 1000 * 60 * 60 * 24;
    var dayOfYear = Math.floor(diff / oneDay);
    var idx = dayOfYear % QUIZ_CATEGORIES.length;
    openQuiz(QUIZ_CATEGORIES[idx].id);
  });
}

/* ── Event Listeners ── */
function bindModalEvents() {
  var btnClose = document.getElementById('btnCloseQuiz');
  if (btnClose) btnClose.addEventListener('click', closeQuiz);

  var btnNext = document.getElementById('btnNextQ');
  if (btnNext) btnNext.addEventListener('click', nextQuestion);

  var btnRestart = document.getElementById('btnRestartQuiz');
  if (btnRestart) btnRestart.addEventListener('click', restartQuiz);

  var btnExit = document.getElementById('btnExitQuiz');
  if (btnExit) btnExit.addEventListener('click', closeQuiz);

  // Close on overlay click outside modal
  if (overlay) {
    overlay.addEventListener('click', function (e) {
      if (e.target === overlay) closeQuiz();
    });
  }

  // Keyboard: Escape closes modal
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && overlay && overlay.classList.contains('open')) {
      closeQuiz();
    }
  });
}

function maybeAutoOpenTopic() {
  var params = new URLSearchParams(window.location.search);
  var topic = params.get('topic');
  if (!topic) return;
  if (!QUIZ_CATEGORIES.some(function (cat) { return cat.id === topic; })) return;
  openQuiz(topic);
}
