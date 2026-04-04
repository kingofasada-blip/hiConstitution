/* ============================================================
   hiConstitution.com — Main JS
   ============================================================ */

'use strict';

/* ── Navbar scroll effect ── */
(function initNavbar() {
  const navbar = document.querySelector('.navbar');
  if (!navbar) return;

  function onScroll() {
    if (window.scrollY > 20) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();

/* ── Mobile menu toggle ── */
(function initMobileMenu() {
  const hamburger = document.querySelector('.hamburger');
  const mobileNav = document.querySelector('.mobile-nav');
  if (!hamburger || !mobileNav) return;

  hamburger.addEventListener('click', function () {
    const isOpen = mobileNav.classList.toggle('open');
    hamburger.classList.toggle('open', isOpen);
    hamburger.setAttribute('aria-expanded', isOpen);
    document.body.style.overflow = isOpen ? 'hidden' : '';
  });

  // Close on link click
  mobileNav.querySelectorAll('.nav-link').forEach(function (link) {
    link.addEventListener('click', function () {
      mobileNav.classList.remove('open');
      hamburger.classList.remove('open');
      hamburger.setAttribute('aria-expanded', 'false');
      document.body.style.overflow = '';
    });
  });

  // Close on outside click
  document.addEventListener('click', function (e) {
    if (!hamburger.contains(e.target) && !mobileNav.contains(e.target)) {
      mobileNav.classList.remove('open');
      hamburger.classList.remove('open');
      hamburger.setAttribute('aria-expanded', 'false');
      document.body.style.overflow = '';
    }
  });
})();

/* ── Mark active nav link ── */
(function markActiveNav() {
  const links = document.querySelectorAll('.nav-link[href]');
  const path = window.location.pathname.split('/').pop() || 'index.html';
  links.forEach(function (link) {
    const href = link.getAttribute('href').split('/').pop();
    if (href === path || (path === '' && href === 'index.html')) {
      link.classList.add('active');
    }
  });
})();

/* ── Smooth scroll for anchor links ── */
(function initSmoothScroll() {
  document.addEventListener('click', function (e) {
    const anchor = e.target.closest('a[href^="#"]');
    if (!anchor) return;
    const id = anchor.getAttribute('href').slice(1);
    const target = document.getElementById(id);
    if (!target) return;
    e.preventDefault();
    const navH = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--navbar-h')) || 68;
    const top = target.getBoundingClientRect().top + window.scrollY - navH - 12;
    window.scrollTo({ top, behavior: 'smooth' });
  });
})();

/* ── Library: Search functionality ── */
(function initLibrarySearch() {
  const searchInput = document.getElementById('articleSearch');
  if (!searchInput) return;

  function filterArticles() {
    const query = searchInput.value.trim().toLowerCase();
    const articleCards = document.querySelectorAll('.article-card[data-search]');
    const noResults = document.getElementById('noResults');
    let visible = 0;

    articleCards.forEach(function (card) {
      const text = card.getAttribute('data-search').toLowerCase();
      const match = !query || text.includes(query);
      card.style.display = match ? '' : 'none';
      if (match) visible++;
    });

    if (noResults) {
      noResults.style.display = visible === 0 ? 'block' : 'none';
    }
  }

  searchInput.addEventListener('input', filterArticles);
  searchInput.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
      searchInput.value = '';
      filterArticles();
    }
  });

  document.addEventListener('library:updated', filterArticles);
})();

/* ── Library: Part filter sidebar ── */
(function initPartFilter() {
  const filterRoot = document.querySelector('.part-filter-list');
  if (!filterRoot) return;

  function filterByPart() {
    const articleCards = document.querySelectorAll('.article-card[data-part]');
    const checkboxes = document.querySelectorAll('.part-filter-item input[type="checkbox"]');
    const checkedParts = [];
    checkboxes.forEach(function (cb) {
      if (cb.checked) checkedParts.push(cb.value);
    });

    articleCards.forEach(function (card) {
      const part = card.getAttribute('data-part');
      if (checkedParts.length === 0 || checkedParts.includes(part)) {
        card.style.display = '';
      } else {
        card.style.display = 'none';
      }
    });
  }

  document.addEventListener('change', function (e) {
    const cb = e.target.closest('.part-filter-item input[type="checkbox"]');
    if (!cb) return;
    const item = cb.closest('.part-filter-item');
    if (item) item.classList.toggle('active', cb.checked);
    filterByPart();
  });

  document.addEventListener('library:updated', filterByPart);
})();

/* ── Library: Simplify toggle ── */
(function initSimplifyToggle() {
  const toggle = document.getElementById('simplifyToggle');
  if (!toggle) return;

  function applyToggle() {
    const isSimplified = toggle.checked;
    const origTexts = document.querySelectorAll('.text-original');
    const simpTexts = document.querySelectorAll('.text-simplified');
    origTexts.forEach(function (el) {
      el.style.display = isSimplified ? 'none' : '';
    });
    simpTexts.forEach(function (el) {
      el.style.display = isSimplified ? '' : 'none';
    });
  }

  // Initially hide simplified
  applyToggle();
  toggle.addEventListener('change', applyToggle);
  document.addEventListener('library:updated', applyToggle);
})();

/* ── Library Article: view tabs (Original / Simplified / Hindi) ── */
(function initArticleViewTabs() {
  const tabs = document.querySelectorAll('.view-tab');
  if (!tabs.length) return;

  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      const view = tab.dataset.view;
      tabs.forEach(function (t) { t.classList.remove('active'); });
      tab.classList.add('active');

      document.querySelectorAll('[data-view-content]').forEach(function (panel) {
        panel.style.display = panel.dataset.viewContent === view ? '' : 'none';
      });
    });
  });
})();

/* ── Tooltip initialization for vocab words ── */
(function initTooltips() {
  // For article pages: hover tooltips on .vocab-highlight spans
  document.querySelectorAll('.vocab-highlight').forEach(function (el) {
    el.setAttribute('tabindex', '0');
    el.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        const tip = el.querySelector('.vocab-tooltip');
        if (tip) tip.style.opacity = tip.style.opacity === '1' ? '0' : '1';
      }
    });
  });
})();

/* ── Hero article 21 card entrance animation ── */
(function initHeroAnimation() {
  const card = document.querySelector('.art21-card');
  if (!card) return;
  card.style.opacity = '0';
  card.style.transform = 'translateY(20px)';
  card.style.transition = 'opacity 0.7s ease 0.3s, transform 0.7s ease 0.3s';
  requestAnimationFrame(function () {
    requestAnimationFrame(function () {
      card.style.opacity = '1';
      card.style.transform = 'translateY(0)';
    });
  });
})();

/* ── Article of the day date stamp ── */
(function setAotdDate() {
  const el = document.getElementById('aotdDate');
  if (!el) return;
  const d = new Date();
  el.textContent = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
})();

/* ── Note card expand/collapse ── */
(function initNoteCards() {
  document.querySelectorAll('.note-header').forEach(function (header) {
    header.addEventListener('click', function () {
      const card = header.closest('.note-card');
      if (!card) return;
      const isOpen = card.classList.toggle('open');
      const body = card.querySelector('.note-body');
      if (body) {
        body.style.maxHeight = isOpen ? body.scrollHeight + 'px' : '0';
      }
    });
  });
})();

/* ── Study page tabs ── */
(function initStudyTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  if (!tabBtns.length) return;

  tabBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      const panelId = btn.dataset.tab;
      tabBtns.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      document.querySelectorAll('.tab-panel').forEach(function (panel) {
        panel.classList.toggle('active', panel.id === panelId);
      });
    });
  });
})();
