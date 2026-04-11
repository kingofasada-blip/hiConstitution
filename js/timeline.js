/* ============================================================
   hiConstitution.com — Interactive Timeline JS
   ============================================================ */

'use strict';

(function initTimeline() {
  const fullTimelineData = [
    { year: '1934', title: 'Idea Proposed', detail: 'M.N. Roy, a pioneer of the communist movement in India, first proposed the idea of a Constituent Assembly to frame a Constitution for India.' },
    { year: '1940', title: 'August Offer', detail: 'The British government accepted the demand for a Constituent Assembly in principle through the "August Offer".' },
    { year: '1946', title: 'Cabinet Mission', detail: 'Elections for the Constituent Assembly were held under the Cabinet Mission Plan. It established the framework for the Assembly.' },
    { year: '1946', title: 'First Meeting', detail: 'On December 9, the Constituent Assembly held its first meeting. Dr. Sachchidananda Sinha was elected as the temporary President.' },
    { year: '1946', title: 'Objective Resolution', detail: 'On December 13, Jawaharlal Nehru moved the historic "Objective Resolution", laying down the philosophical fundamentals of the constitutional structure.' },
    { year: '1947', title: 'National Flag Adopted', detail: 'On July 22, the Constituent Assembly adopted the National Flag of India.' },
    { year: '1947', title: 'Indian Independence', detail: 'India attained independence on August 15, 1947. The Constituent Assembly became the fully sovereign body tasked with drafting the Constitution.' },
    { year: '1947', title: 'Drafting Committee', detail: 'On August 29, the Drafting Committee was appointed with Dr. B.R. Ambedkar as its Chairman to prepare a draft constitution.' },
    { year: '1948', title: 'First Draft Published', detail: 'The Drafting Committee published the first Draft of the Constitution in February, giving the public 8 months to discuss it and propose amendments.' },
    { year: '1949', title: 'Constitution Adopted', detail: 'The Constitution of India was adopted by the Constituent Assembly on November 26, 1949. It was signed by 284 members. The date is now celebrated as Constitution Day.' },
    { year: '1950', title: 'Final Session', detail: 'On January 24, the Assembly held its final session. It adopted the National Anthem and National Song, and elected Dr. Rajendra Prasad as the first President.' },
    { year: '1950', title: 'Constitution Commenced', detail: 'The Constitution of India came into full legal force on January 26, 1950, replacing the Government of India Act (1935). The date is celebrated as Republic Day.' },
    { year: '1951', title: 'First Amendment', detail: 'Added the Ninth Schedule to protect land reform laws from judicial review, and restricted freedom of speech in certain circumstances.' },
    { year: '1973', title: 'Basic Structure Doctrine', detail: 'In the landmark Kesavananda Bharati case, the Supreme Court ruled that Parliament cannot alter the "Basic Structure" of the Constitution.' },
    { year: '1976', title: '42nd Amendment', detail: 'Enacted during the Emergency, known as the "Mini-Constitution". It added "Socialist", "Secular", and "Integrity" to the Preamble, and inserted Fundamental Duties.' },
    { year: '1978', title: '44th Amendment', detail: 'Reversed distortions of the 42nd Amendment. Removed the "Right to Property" from Fundamental Rights, making it a legal right.' },
    { year: '1992', title: 'Local Self-Government', detail: 'The 73rd and 74th Amendments gave constitutional status to Panchayats and Municipalities, creating a 3-tier system of administration.' },
    { year: '2017', title: 'Right to Privacy', detail: 'A 9-judge bench in the Puttaswamy case unanimously ruled that the Right to Privacy is a Fundamental Right under Article 21.' },
    { year: '2023', title: 'Women\'s Reservation', detail: 'The 106th Amendment reserved 33% of seats in the Lok Sabha and State Legislative Assemblies for women.' }
  ];

  // Logic for index.html (Horizontal Scrolling Timeline)
  const track = document.getElementById('timelineTrack');
  const detailsPanel = document.getElementById('timelineDetails');
  if (track && detailsPanel) {
    const homeEvents = [
      fullTimelineData[2],  // Cabinet Mission 1946
      fullTimelineData[6],  // Independence 1947
      fullTimelineData[9],  // Adopted 1949
      fullTimelineData[11], // Commenced 1950
      fullTimelineData[12]  // 1st Amendment 1951
    ];

    let activeIndex = -1;

    homeEvents.forEach(function (item, index) {
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

      detailsPanel.querySelector('.timeline-details-year').textContent = item.year;
      detailsPanel.querySelector('.timeline-details-content h3').textContent = item.title;
      detailsPanel.querySelector('.timeline-details-content p').textContent = item.detail;
      detailsPanel.classList.add('open');
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }

    const scrollWrap = document.querySelector('.timeline-scroll-wrap');
    if (scrollWrap) {
      let isDown = false; let startX; let scrollLeft;
      scrollWrap.addEventListener('mousedown', function (e) {
        isDown = true; startX = e.pageX - scrollWrap.offsetLeft; scrollLeft = scrollWrap.scrollLeft;
      });
      scrollWrap.addEventListener('mouseleave', function () { isDown = false; });
      scrollWrap.addEventListener('mouseup', function () { isDown = false; });
      scrollWrap.addEventListener('mousemove', function (e) {
        if (!isDown) return; e.preventDefault();
        const walk = (e.pageX - scrollWrap.offsetLeft - startX) * 1.5;
        scrollWrap.scrollLeft = scrollLeft - walk;
      });
      let touchStartX = 0; let touchScrollLeft = 0;
      scrollWrap.addEventListener('touchstart', function (e) {
        touchStartX = e.touches[0].pageX; touchScrollLeft = scrollWrap.scrollLeft;
      }, { passive: true });
      scrollWrap.addEventListener('touchmove', function (e) {
        scrollWrap.scrollLeft = touchScrollLeft - (e.touches[0].pageX - touchStartX);
      }, { passive: true });
    }
  }

  // Logic for timeline.html (Vertical List View)
  const vertContainer = document.getElementById('verticalTimeline');
  if (vertContainer) {
    fullTimelineData.forEach((item) => {
      const el = document.createElement('div');
      el.className = 'v-timeline-item';
      el.innerHTML = `
        <div class="v-timeline-dot">${item.year}</div>
        <div class="v-timeline-content">
          <h3 style="color:var(--navy); margin-bottom:8px;">${item.title}</h3>
          <p style="color:var(--body-text); font-size:0.95rem; line-height:1.6; margin:0;">${item.detail}</p>
        </div>
      `;
      vertContainer.appendChild(el);
    });
  }
})();
