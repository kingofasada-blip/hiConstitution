/* ============================================================
   hiConstitution.com — Interactive Timeline JS
   ============================================================ */

'use strict';

(function initTimeline() {

  /* ── Full dataset ── */
  const fullTimelineData = [
    {
      year: '1934', title: 'Idea Proposed',
      category: 'formation', icon: '💡',
      detail: 'M.N. Roy first proposed the idea of a Constituent Assembly to draft a Constitution for India — the earliest formal articulation of the demand for self-governance through a people\'s body.'
    },
    {
      year: '1940', title: 'August Offer',
      category: 'formation', icon: '📜',
      detail: 'The British government, through the "August Offer", accepted in principle that India would have a Constituent Assembly after the war — a significant, if hollow, concession that kept the demand alive.'
    },
    {
      year: '1942', title: 'Cripps Mission',
      category: 'formation', icon: '🤝',
      detail: 'The British sent Sir Stafford Cripps to India with proposals for post-war dominion status and a Constituent Assembly. The offer was rejected by the Congress as it allowed provinces to opt out.'
    },
    {
      year: '1946', title: 'Cabinet Mission',
      category: 'formation', icon: '🏛️',
      detail: 'Elections for the Constituent Assembly were held under the Cabinet Mission Plan. Of 389 seats, 292 were won by the Congress. The framework for drafting the Constitution was finally in place.'
    },
    {
      year: '1946', title: 'Assembly Convenes',
      category: 'drafting', icon: '🔔',
      detail: 'On December 9, the Constituent Assembly held its historic first meeting. Dr. Sachchidananda Sinha was elected temporary President. Pakistan refused to participate, reducing the Assembly to 299 members.'
    },
    {
      year: '1946', title: 'Objective Resolution',
      category: 'drafting', icon: '⭐',
      detail: 'On December 13, Jawaharlal Nehru moved the "Objective Resolution" — the philosophical soul of the Constitution. It declared India to be an independent sovereign republic with justice, liberty, equality, and fraternity for all citizens.'
    },
    {
      year: '1947', title: 'National Flag Adopted',
      category: 'drafting', icon: '🇮🇳',
      detail: 'On July 22, the Constituent Assembly adopted the tricolour National Flag of India. The Ashoka Chakra replaced the spinning wheel of Gandhi, symbolising the wheel of dharma and perpetual motion.'
    },
    {
      year: '1947', title: 'Independence',
      category: 'drafting', icon: '🕊️',
      detail: 'India attained independence at midnight on August 15, 1947. The Constituent Assembly became the fully sovereign body of independent India, now accountable to the people alone — not the Crown.'
    },
    {
      year: '1947', title: 'Drafting Committee',
      category: 'drafting', icon: '✍️',
      detail: 'On August 29, the seven-member Drafting Committee was appointed with Dr. B.R. Ambedkar as Chairman. Ambedkar would spend the next three years crafting the most detailed constitution in the world.'
    },
    {
      year: '1948', title: 'Draft Published',
      category: 'drafting', icon: '📋',
      detail: 'In February, the Drafting Committee published the first Draft Constitution of 395 Articles and 8 Schedules. The public was given 8 months to discuss it — over 7,635 amendments were proposed by members.'
    },
    {
      year: '1949', title: 'Constitution Adopted',
      category: 'republic', icon: '✅',
      detail: 'On November 26, 1949 — now celebrated as Constitution Day — the Constituent Assembly adopted the Constitution. 284 members signed the handwritten, calligraphed original. Dr. Ambedkar called it "the most celebrated date in history".'
    },
    {
      year: '1950', title: 'Republic Day',
      category: 'republic', icon: '🌅',
      detail: 'The Constitution came into full force on January 26, 1950 — chosen to honour the Purna Swaraj Declaration of 1930. India officially became a Sovereign Democratic Republic. Dr. Rajendra Prasad became the first President.'
    },
    {
      year: '1951', title: '1st Amendment',
      category: 'amendment', icon: '⚖️',
      detail: 'Added the Ninth Schedule to protect land reform laws from judicial review, and inserted reasonable restrictions on freedom of speech. The Constitution was changed for the first time, just 15 months after its commencement.'
    },
    {
      year: '1973', title: 'Basic Structure',
      category: 'landmark', icon: '🏛️',
      detail: 'In Kesavananda Bharati v. State of Kerala, a 13-judge bench ruled 7-6 that Parliament cannot alter the "Basic Structure" of the Constitution. This doctrine has since protected Indian democracy from authoritarian amendments.'
    },
    {
      year: '1975', title: 'Emergency Declared',
      category: 'landmark', icon: '⚠️',
      detail: 'PM Indira Gandhi declared a National Emergency under Article 352, citing internal disturbance. Fundamental Rights were suspended, press was censored, and political opponents were jailed — the darkest chapter in India\'s democratic history.'
    },
    {
      year: '1976', title: '42nd Amendment',
      category: 'amendment', icon: '📝',
      detail: 'Passed during the Emergency, called the "Mini-Constitution". It added "Socialist", "Secular", and "Integrity" to the Preamble; inserted Fundamental Duties (Part IVA); and severely curtailed the Supreme Court\'s power of judicial review.'
    },
    {
      year: '1978', title: '44th Amendment',
      category: 'amendment', icon: '🔄',
      detail: 'Enacted by the Janata government to restore democracy. It reversed the key distortions of the 42nd Amendment, removed the "Right to Property" from Fundamental Rights (Article 19 & 31), and strengthened protections against Emergency misuse.'
    },
    {
      year: '1992', title: 'Panchayati Raj',
      category: 'amendment', icon: '🏘️',
      detail: 'The 73rd and 74th Amendments gave constitutional status to Panchayats and Municipalities, establishing India\'s 3-tier democratic structure. One-third of seats were reserved for women — a revolution in grassroots democracy.'
    },
    {
      year: '2017', title: 'Right to Privacy',
      category: 'landmark', icon: '🔒',
      detail: 'A historic 9-judge bench unanimously ruled in Justice K.S. Puttaswamy v. Union of India that the Right to Privacy is a Fundamental Right under Article 21. This ruling has since shaped data protection, surveillance, and personal liberty jurisprudence.'
    },
    {
      year: '2023', title: 'Women\'s Reservation',
      category: 'amendment', icon: '⚡',
      detail: 'The Constitution (106th Amendment) Act reserved one-third of seats in the Lok Sabha and State Legislative Assemblies for women — a landmark step toward equal political representation, pending a delimitation exercise.'
    }
  ];

  /* ── Category metadata ── */
  const categoryMeta = {
    formation: { label: 'Formation',   color: 'var(--muted)',        bg: 'var(--bg-subtle)' },
    drafting:  { label: 'Drafting',    color: 'var(--navy)',         bg: 'var(--navy-bg)'   },
    republic:  { label: 'Republic',    color: '#2e7d32',             bg: 'rgba(46,125,50,0.08)' },
    amendment: { label: 'Amendment',   color: 'var(--saffron)',      bg: 'var(--saffron-bg)' },
    landmark:  { label: 'Landmark',    color: '#7b1fa2',             bg: 'rgba(123,31,162,0.08)' },
  };

  /* ════════════════════════════════════════════════════════════
     HOME PAGE  —  Horizontal scrolling timeline
  ════════════════════════════════════════════════════════════ */
  const track = document.getElementById('timelineTrack');
  const detailsPanel = document.getElementById('timelineDetails');

  if (track && detailsPanel) {
    // Pick 7 spread events covering the full story arc
    const homeEvents = [
      fullTimelineData[3],  // Cabinet Mission 1946
      fullTimelineData[7],  // Independence 1947
      fullTimelineData[8],  // Drafting Committee 1947
      fullTimelineData[10], // Constitution Adopted 1949
      fullTimelineData[11], // Republic Day 1950
      fullTimelineData[13], // Basic Structure 1973
      fullTimelineData[18], // Right to Privacy 2017
    ];

    let activeIndex = -1;

    homeEvents.forEach(function (item, index) {
      const cat = categoryMeta[item.category] || categoryMeta.formation;
      const el = document.createElement('div');
      el.className = 'timeline-item';
      el.setAttribute('role', 'button');
      el.setAttribute('tabindex', '0');
      el.setAttribute('aria-expanded', 'false');
      el.setAttribute('aria-label', item.year + ' — ' + item.title);
      el.innerHTML =
        '<div class="timeline-dot-wrap">' +
          '<div class="timeline-dot" style="--cat-color:' + cat.color + ';--cat-bg:' + cat.bg + '">' +
            '<span class="timeline-dot-icon">' + item.icon + '</span>' +
          '</div>' +
        '</div>' +
        '<div class="timeline-year">' + item.year + '</div>' +
        '<div class="timeline-title">' + item.title + '</div>';

      el.addEventListener('click', function () { activateItem(index, el, item); });
      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); activateItem(index, el, item); }
      });
      track.appendChild(el);
    });

    // Auto-activate the most pivotal event (Constitution Adopted) on load
    const defaultIdx = 3;
    const defaultEl = track.querySelectorAll('.timeline-item')[defaultIdx];
    if (defaultEl) activateItem(defaultIdx, defaultEl, homeEvents[defaultIdx]);

    function activateItem(index, el, item) {
      const allItems = track.querySelectorAll('.timeline-item');
      // Toggle off if already active
      if (activeIndex === index) {
        el.classList.remove('active');
        el.setAttribute('aria-expanded', 'false');
        detailsPanel.classList.remove('open');
        activeIndex = -1;
        return;
      }
      allItems.forEach(function (i) {
        i.classList.remove('active');
        i.setAttribute('aria-expanded', 'false');
      });
      el.classList.add('active');
      el.setAttribute('aria-expanded', 'true');
      activeIndex = index;

      const cat = categoryMeta[item.category] || categoryMeta.formation;
      detailsPanel.querySelector('.timeline-details-year').textContent = item.year;
      detailsPanel.querySelector('.timeline-details-icon').textContent = item.icon;
      detailsPanel.querySelector('.timeline-details-category').textContent = cat.label;
      detailsPanel.querySelector('.timeline-details-category').style.color = cat.color;
      detailsPanel.querySelector('.timeline-details-category').style.background = cat.bg;
      detailsPanel.querySelector('.timeline-details-content h3').textContent = item.title;
      detailsPanel.querySelector('.timeline-details-content p').textContent = item.detail;
      detailsPanel.classList.add('open');
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }

    /* ── Drag-to-scroll ── */
    const scrollWrap = document.querySelector('.timeline-scroll-wrap');
    if (scrollWrap) {
      let isDown = false, startX, scrollLeft, hasDragged = false;
      scrollWrap.addEventListener('mousedown', function (e) {
        isDown = true; hasDragged = false;
        startX = e.pageX - scrollWrap.offsetLeft;
        scrollLeft = scrollWrap.scrollLeft;
      });
      scrollWrap.addEventListener('mouseleave', function () { isDown = false; });
      scrollWrap.addEventListener('mouseup', function () { isDown = false; });
      scrollWrap.addEventListener('mousemove', function (e) {
        if (!isDown) return;
        e.preventDefault();
        hasDragged = true;
        const walk = (e.pageX - scrollWrap.offsetLeft - startX) * 1.4;
        scrollWrap.scrollLeft = scrollLeft - walk;
      });
      // Touch
      let touchStartX = 0, touchScrollLeft = 0;
      scrollWrap.addEventListener('touchstart', function (e) {
        touchStartX = e.touches[0].pageX;
        touchScrollLeft = scrollWrap.scrollLeft;
      }, { passive: true });
      scrollWrap.addEventListener('touchmove', function (e) {
        scrollWrap.scrollLeft = touchScrollLeft - (e.touches[0].pageX - touchStartX);
      }, { passive: true });
    }
  }

  /* ════════════════════════════════════════════════════════════
     FULL TIMELINE PAGE  —  Vertical list with category filter
  ════════════════════════════════════════════════════════════ */
  const vertContainer = document.getElementById('verticalTimeline');
  const filterBtns = document.querySelectorAll('.tl-filter-btn');

  if (vertContainer) {
    let activeFilter = 'all';

    function renderVertical(filter) {
      vertContainer.innerHTML = '';
      const items = filter === 'all'
        ? fullTimelineData
        : fullTimelineData.filter(function (d) { return d.category === filter; });

      items.forEach(function (item) {
        const cat = categoryMeta[item.category] || categoryMeta.formation;
        const el = document.createElement('div');
        el.className = 'v-timeline-item';
        el.dataset.category = item.category;
        el.innerHTML =
          '<div class="v-timeline-dot" style="border-color:' + cat.color + '; color:' + cat.color + '">' +
            '<span class="v-dot-icon">' + item.icon + '</span>' +
          '</div>' +
          '<div class="v-timeline-content" style="border-left-color:' + cat.color + '">' +
            '<div class="v-timeline-header">' +
              '<span class="v-timeline-year-label">' + item.year + '</span>' +
              '<span class="v-timeline-badge" style="color:' + cat.color + '; background:' + cat.bg + '">' + cat.label + '</span>' +
            '</div>' +
            '<h3 class="v-timeline-title">' + item.title + '</h3>' +
            '<p class="v-timeline-detail">' + item.detail + '</p>' +
          '</div>';
        vertContainer.appendChild(el);
      });
    }

    renderVertical('all');

    filterBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        filterBtns.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        activeFilter = btn.dataset.filter;
        renderVertical(activeFilter);
      });
    });
  }

})();
