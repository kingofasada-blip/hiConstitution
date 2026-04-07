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

/* ── Article of the Day Logic ── */
(function initArticleOfTheDay() {
  const el = document.getElementById('aotdDate');
  if (!el) return;
  
  const d = new Date();
  el.textContent = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });

  const AOTD_DATABASE = [
    { num: "21", title: "Right to Life & Personal Liberty", quote: "\"No person shall be deprived of his life or personal liberty except according to procedure established by law.\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "A cornerstone of the Constitution, Article 21 has been expansively interpreted by the Supreme Court to include the right to privacy, clean environment, and free legal aid, making it the most dynamic fundamental right." },
    { num: "32", title: "Right to Constitutional Remedies", quote: "\"The right to move the Supreme Court by appropriate proceedings for the enforcement of the rights conferred by this Part is guaranteed.\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "Called the 'heart and soul of the Constitution' by Dr. B.R. Ambedkar, Article 32 empowers every citizen to approach the Supreme Court directly to enforce their Fundamental Rights through writs." },
    { num: "14", title: "Right to Equality", quote: "\"The State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India.\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "Article 14 ensures that no person is above the law and that everyone is treated equally by the State, forming the foundation of the Rule of Law in India." },
    { num: "19", title: "Freedom of Speech and Expression", quote: "\"All citizens shall have the right to freedom of speech and expression; to assemble peaceably...\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "Article 19 guarantees six essential freedoms to citizens, including speech, assembly, and movement, subject to reasonable restrictions for sovereignty and public order." },
    { num: "51A", title: "Fundamental Duties", quote: "\"It shall be the duty of every citizen of India to abide by the Constitution and respect its ideals and institutions...\"", tag: "Fundamental Duties · Part IVA", part: "Part IVA", badge: "Fundamental Duty", snippet: "Added by the 42nd Amendment, these 11 duties serve as a constant reminder to citizens that while the Constitution grants them rights, it also expects them to observe certain basic norms of democratic conduct." },
    { num: "44", title: "Uniform Civil Code", quote: "\"The State shall endeavour to secure for the citizens a uniform civil code throughout the territory of India.\"", tag: "Directive Principles · Part IV", part: "Part IV", badge: "Directive Principle", snippet: "A significant and highly debated Directive Principle that guides the State to formulate a single set of personal laws governing marriage, divorce, and inheritance for all citizens." },
    { num: "368", title: "Power to Amend the Constitution", quote: "\"Parliament may in exercise of its constituent power amend by way of addition, variation or repeal any provision of this Constitution...\"", tag: "Amendment Power · Part XX", part: "Part XX", badge: "Constitutional Power", snippet: "This article grants Parliament the power to amend the Constitution, keeping it a 'living document'. However, the Supreme Court ruled that the 'Basic Structure' cannot be altered." },
    { num: "15", title: "Prohibition of Discrimination", quote: "\"The State shall not discriminate against any citizen on grounds only of religion, race, caste, sex, place of birth or any of them.\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "Article 15 prohibits discrimination by the State and ensures equal access to public places, while allowing special provisions for women, children, and socially/educationally backward classes." },
    { num: "17", title: "Abolition of Untouchability", quote: "\"Untouchability is abolished and its practice in any form is forbidden.\"", tag: "Fundamental Rights · Part III", part: "Part III", badge: "Fundamental Right", snippet: "A historic provision aimed at eradicating a centuries-old social evil, Article 17 makes the practice of untouchability a punishable offence under the law." },
    { num: "40", title: "Organisation of Village Panchayats", quote: "\"The State shall take steps to organise village panchayats and endow them with such powers and authority...\"", tag: "Directive Principles · Part IV", part: "Part IV", badge: "Directive Principle", snippet: "Reflecting Gandhian ideals, Article 40 directs the State to organize village panchayats as units of self-government, which was later fully realized through the 73rd Amendment." },
    { num: "52", title: "The President of India", quote: "\"There shall be a President of India.\"", tag: "The Union · Part V", part: "Part V", badge: "Executive Power", snippet: "This concise yet powerful article establishes the highest office of the land, making the President the head of state and the supreme commander of the Indian Armed Forces." },
    { num: "324", title: "Election Commission", quote: "\"The superintendence, direction and control of the preparation of the electoral rolls for, and the conduct of, all elections... shall be vested in a Commission.\"", tag: "Elections · Part XV", part: "Part XV", badge: "Constitutional Body", snippet: "Article 324 guarantees the independence of the Election Commission of India, ensuring free and fair elections for Parliament and State Legislatures." }
  ];

  const start = new Date(d.getFullYear(), 0, 0);
  const diff = d - start;
  const oneDay = 1000 * 60 * 60 * 24;
  const dayOfYear = Math.floor(diff / oneDay);
  const article = AOTD_DATABASE[dayOfYear % AOTD_DATABASE.length];

  const heroNum = document.getElementById('heroAotdNum');
  if (heroNum) {
    heroNum.textContent = article.num;
    document.getElementById('heroAotdTitle').textContent = article.title;
    document.getElementById('heroAotdQuote').textContent = article.quote;
    document.getElementById('heroAotdTag').innerHTML = article.tag.replace(' · ', ' &nbsp;&middot;&nbsp; ');
  }

  const bottomNum = document.getElementById('bottomAotdNum');
  if (bottomNum) {
    bottomNum.textContent = article.num;
    document.getElementById('bottomAotdTitle').textContent = `Article ${article.num} - ${article.title}`;
    document.getElementById('bottomAotdBadge').textContent = article.badge;
    document.getElementById('bottomAotdPart').textContent = article.part;
    document.getElementById('bottomAotdSnippet').textContent = article.snippet;
    const link = document.getElementById('bottomAotdLink');
    if (link) link.href = `library-article.html?id=${article.num}`;
  }
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
