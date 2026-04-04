/* ============================================================
   hiConstitution.com — Interactive Timeline JS
   ============================================================ */

'use strict';

(function initTimeline() {
  const timelineData = [
    {
      year: '1946',
      title: 'Constituent Assembly Formed',
      detail: 'The Constituent Assembly of India was formed under the Cabinet Mission Plan of 1946. It held its first session on December 9, 1946. Dr. Sachchidananda Sinha was the temporary president and Dr. Rajendra Prasad was elected as its permanent President.',
    },
    {
      year: '1947',
      title: 'Indian Independence',
      detail: 'India attained independence on August 15, 1947. The Constituent Assembly became the sovereign body tasked with drafting the Constitution. Dr. B.R. Ambedkar was appointed Chairman of the Drafting Committee on August 29, 1947.',
    },
    {
      year: '1949',
      title: 'Constitution Adopted',
      detail: 'The Constitution of India was adopted by the Constituent Assembly on November 26, 1949. It was signed by 284 members. The date is now celebrated as Constitution Day (Samvidhan Divas) in India.',
    },
    {
      year: '1950',
      title: 'Constitution Commenced',
      detail: 'The Constitution of India came into force on January 26, 1950, replacing the Government of India Act (1935). Dr. Rajendra Prasad became the first President. The date is celebrated as Republic Day each year.',
    },
    {
      year: '1951',
      title: 'First Amendment',
      detail: 'The Constitution (First Amendment) Act, 1951 amended Articles 15, 19, 85, 87, 174, 176, 341, 342, 372, and 376. It added the Ninth Schedule to protect land reform laws from judicial review and restricted freedom of speech in certain circumstances.',
    },
  ];

  const track = document.getElementById('timelineTrack');
  const detailsPanel = document.getElementById('timelineDetails');

  if (!track || !detailsPanel) return;

  let activeIndex = -1;

  // Build timeline items
  timelineData.forEach(function (item, index) {
    const el = document.createElement('div');
    el.className = 'timeline-item';
    el.setAttribute('role', 'button');
    el.setAttribute('tabindex', '0');
    el.setAttribute('aria-expanded', 'false');
    el.innerHTML =
      '<div class="timeline-dot-wrap">' +
        '<div class="timeline-dot">' +
          '<span>' + item.year.slice(2) + '</span>' +
        '</div>' +
      '</div>' +
      '<div class="timeline-year">' + item.year + '</div>' +
      '<div class="timeline-title">' + item.title + '</div>';

    el.addEventListener('click', function () { toggleItem(index, el, item); });
    el.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        toggleItem(index, el, item);
      }
    });

    track.appendChild(el);
  });

  function toggleItem(index, el, item) {
    const allItems = track.querySelectorAll('.timeline-item');

    if (activeIndex === index) {
      // Collapse
      el.classList.remove('active');
      el.setAttribute('aria-expanded', 'false');
      detailsPanel.classList.remove('open');
      activeIndex = -1;
      return;
    }

    // Expand new
    allItems.forEach(function (i) {
      i.classList.remove('active');
      i.setAttribute('aria-expanded', 'false');
    });
    el.classList.add('active');
    el.setAttribute('aria-expanded', 'true');
    activeIndex = index;

    // Set content
    detailsPanel.querySelector('.timeline-details-year').textContent = item.year;
    detailsPanel.querySelector('.timeline-details-content h3').textContent = item.title;
    detailsPanel.querySelector('.timeline-details-content p').textContent = item.detail;

    // Open panel
    detailsPanel.classList.add('open');

    // Scroll item into view (mobile)
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
  }

  // Drag-to-scroll on desktop
  const scrollWrap = document.querySelector('.timeline-scroll-wrap');
  if (scrollWrap) {
    let isDown = false;
    let startX;
    let scrollLeft;

    scrollWrap.addEventListener('mousedown', function (e) {
      isDown = true;
      startX = e.pageX - scrollWrap.offsetLeft;
      scrollLeft = scrollWrap.scrollLeft;
    });
    scrollWrap.addEventListener('mouseleave', function () { isDown = false; });
    scrollWrap.addEventListener('mouseup', function () { isDown = false; });
    scrollWrap.addEventListener('mousemove', function (e) {
      if (!isDown) return;
      e.preventDefault();
      const x = e.pageX - scrollWrap.offsetLeft;
      const walk = (x - startX) * 1.5;
      scrollWrap.scrollLeft = scrollLeft - walk;
    });

    // Touch events
    let touchStartX = 0;
    let touchScrollLeft = 0;
    scrollWrap.addEventListener('touchstart', function (e) {
      touchStartX = e.touches[0].pageX;
      touchScrollLeft = scrollWrap.scrollLeft;
    }, { passive: true });
    scrollWrap.addEventListener('touchmove', function (e) {
      const dx = e.touches[0].pageX - touchStartX;
      scrollWrap.scrollLeft = touchScrollLeft - dx;
    }, { passive: true });
  }
})();
