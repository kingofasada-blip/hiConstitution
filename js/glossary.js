/* ============================================================
   hiConstitution.com — Glossary JS
   ============================================================ */

'use strict';

var GLOSSARY_TERMS = [
  { term: 'Amendment', pronunciation: 'uh-MEND-ment', definition: 'A formal change or addition made to the Constitution under Article 368. The Constitution can be amended by a special majority of Parliament and, in some cases, with ratification by state legislatures.', usage: 'The Constitution (42nd Amendment) Act, 1976 made significant changes to the Preamble and Fundamental Rights.' },
  { term: 'Article', pronunciation: 'AR-ti-kul', definition: 'The basic unit of the Constitution of India. There are 448 articles in the current Constitution, each dealing with a specific provision or rule of law.', usage: 'Article 21 guarantees the right to life and personal liberty to every person.' },
  { term: 'Certiorari', pronunciation: 'sur-shuh-RAY-ree', definition: 'A writ issued by a superior court to call up the records of a lower court or tribunal to examine the legality of its proceedings. It is used to quash decisions made without jurisdiction or in violation of natural justice.', usage: 'The Supreme Court issued a writ of certiorari to quash the order of the tribunal that had acted without jurisdiction.' },
  { term: 'Clause', pronunciation: 'KLAWZ', definition: 'A subdivision of an article in the Constitution. Articles are often divided into clauses, sub-clauses, and further subcategories.', usage: 'Article 19(1)(a) is Clause (1), sub-clause (a) of Article 19, which guarantees freedom of speech.' },
  { term: 'Constituent Assembly', pronunciation: 'kon-STICH-oo-ent uh-SEM-blee', definition: 'The body convened to draft and adopt the Constitution of India. It consisted of 389 members elected by the provincial assemblies. It first met on December 9, 1946 and finally adopted the Constitution on November 26, 1949.', usage: 'The Constituent Assembly deliberated for nearly three years before adopting the Constitution.' },
  { term: 'Democratic', pronunciation: 'dem-uh-KRAT-ik', definition: 'A system of government in which supreme power is vested in the people through elected representatives. India is a representative democracy where citizens elect their rulers through free and fair elections.', usage: 'India is a Democratic Republic as stated in the Preamble to the Constitution.' },
  { term: 'Directive Principles', pronunciation: 'duh-REK-tiv PRIN-suh-pulz', definition: 'Guidelines in Part IV (Articles 36–51) of the Constitution directing the State to implement social, economic, and political justice. Unlike Fundamental Rights, they are non-justiciable—courts cannot enforce them—but they are fundamental to governance.', usage: 'Article 39 contains Directive Principles regarding equal pay for equal work and adequate means of livelihood.' },
  { term: 'Emergency', pronunciation: 'ih-MUR-jen-see', definition: 'A constitutional provision under Articles 352, 356, and 360 allowing special powers to the central government during crises. There are three types: National Emergency, President\'s Rule, and Financial Emergency.', usage: 'A National Emergency was proclaimed under Article 352 during the 1975 internal disturbance.' },
  { term: 'Fundamental Duties', pronunciation: 'fun-duh-MEN-tul DYOO-teez', definition: 'Obligations of citizens listed in Article 51A (Part IVA), added by the 42nd Amendment in 1976. There are now 11 fundamental duties, including respecting the Constitution, defending the nation, and protecting public property.', usage: 'It is the Fundamental Duty of every citizen under Article 51A(h) to develop scientific temper.' },
  { term: 'Fundamental Rights', pronunciation: 'fun-duh-MEN-tul RYTS', definition: 'Basic human rights guaranteed to all citizens by Part III (Articles 12–35) of the Constitution. They are justiciable—enforceable by courts. They include rights to equality, freedom, protection from exploitation, religion, culture, and constitutional remedies.', usage: 'The right to equality under Article 14 is a Fundamental Right available to all persons in India.' },
  { term: 'Habeas Corpus', pronunciation: 'HAY-bee-us KOR-pus', definition: 'Latin for "you shall have the body." A writ issued by a court requiring that a person held in custody be brought before the court. It is the primary safeguard against illegal detention and is available under Article 32 and 226.', usage: 'The Supreme Court issued a writ of habeas corpus to release a person who was illegally detained by the police.' },
  { term: 'Judiciary', pronunciation: 'joo-DISH-ee-er-ee', definition: 'The branch of government comprising the Supreme Court, High Courts, and subordinate courts that interpret laws, resolve disputes, and protect constitutional rights. India has an integrated judicial system headed by the Supreme Court.', usage: 'The independence of the Judiciary is considered a basic feature of the Constitution.' },
  { term: 'Mandamus', pronunciation: 'man-DAY-mus', definition: 'Latin for "we command." A writ issued by a superior court commanding a government official, lower court, or public authority to perform a public duty that it has refused or failed to perform.', usage: 'The High Court issued a writ of mandamus directing the municipal authority to supply drinking water to the residents.' },
  { term: 'Preamble', pronunciation: 'PREE-am-bul', definition: 'The introductory statement to the Constitution that sets out the guiding values and objectives. It declares India to be a Sovereign, Socialist, Secular, Democratic Republic aimed at securing justice, liberty, equality, and fraternity for all citizens.', usage: 'The Preamble was amended by the 42nd Amendment to add the words "Socialist" and "Secular."' },
  { term: 'President\'s Rule', pronunciation: 'PREZ-i-dents ROOL', definition: 'Also called State Emergency or Article 356 Emergency. Proclaimed when constitutional machinery fails in a state, allowing the central government to assume control of the state\'s executive functions.', usage: 'President\'s Rule was imposed in the state after the government lost its majority in the legislative assembly.' },
  { term: 'Prohibition', pronunciation: 'proh-ih-BISH-un', definition: 'A writ issued by a superior court to a lower court or tribunal directing it to stop proceedings in a matter that is outside its jurisdiction or that it is handling contrary to natural justice.', usage: 'The High Court issued a writ of prohibition against the lower court that was proceeding without jurisdiction.' },
  { term: 'Quo Warranto', pronunciation: 'KWOH wuh-RAN-toh', definition: 'Latin for "by what authority." A writ requiring a person holding a public office to show by what authority they hold or claim that office. It is used to prevent illegal usurpation of public offices.', usage: 'The court issued a writ of quo warranto against the person who was illegally occupying a constitutional office.' },
  { term: 'Republic', pronunciation: 'rih-PUB-lik', definition: 'A form of government in which the head of state is an elected or appointed person rather than a hereditary monarch. India is a Republic because the President, as the head of state, is elected.', usage: 'India became a Republic on January 26, 1950, when the Constitution came into force.' },
  { term: 'Schedule', pronunciation: 'SKED-yool', definition: 'Supplements to the Constitution that provide additional details for specific constitutional provisions. There are 12 Schedules covering topics like state allocation, oaths, languages, anti-defection, tribal areas, and more.', usage: 'The Eighth Schedule lists the 22 official languages of India recognised by the Constitution.' },
  { term: 'Secular', pronunciation: 'SEK-yuh-lur', definition: 'A principle by which the State treats all religions equally and does not promote or favour any particular religion. India is a secular state that guarantees freedom of religion to all citizens under Articles 25–28.', usage: 'The word "Secular" was inserted into the Preamble by the 42nd Constitutional Amendment, 1976.' },
  { term: 'Socialist', pronunciation: 'SOH-shuh-list', definition: 'A principle directing the State to secure an equitable distribution of resources and reduce inequalities in income, status, and wealth. Added to the Preamble by the 42nd Amendment in 1976.', usage: 'The word "Socialist" in the Preamble reflects the commitment to eliminating economic inequality.' },
  { term: 'Sovereign', pronunciation: 'SOV-rin', definition: 'Having supreme and independent authority. India is a Sovereign state, meaning it is free from external control and can make its own internal and external policies without interference from any foreign power.', usage: 'India\'s status as a Sovereign nation means it cannot cede its territory to another country.' },
  { term: 'Union List', pronunciation: 'YOON-yun LIST', definition: 'List I of the Seventh Schedule. It contains 100 subjects (originally 97) on which only the Parliament of India has the exclusive power to legislate. Subjects include defence, atomic energy, foreign affairs, railways, and banking.', usage: 'Defence and foreign affairs are subjects under the Union List and are legislated upon only by Parliament.' },
  { term: 'Concurrent List', pronunciation: 'kun-KUR-unt LIST', definition: 'List III of the Seventh Schedule. It contains 52 subjects (originally 47) on which both Parliament and state legislatures can legislate. In case of conflict, the central law prevails.', usage: 'Education and criminal law are in the Concurrent List, allowing both Parliament and states to legislate on them.' },
  { term: 'State List', pronunciation: 'STAYT LIST', definition: 'List II of the Seventh Schedule. It originally contained 66 subjects on which only state legislatures have the power to legislate, such as police, public health, and agriculture.', usage: 'Agriculture and public order are State List subjects, legislated upon by state governments.' },
  { term: 'Writ', pronunciation: 'RIT', definition: 'A formal written order issued by a court to an authority or individual commanding them to do or refrain from doing a specific act. Under Article 32, the Supreme Court and under Article 226, High Courts can issue writs.', usage: 'A citizen filed a writ petition in the High Court seeking enforcement of their fundamental rights.' },
  { term: 'Rajya Sabha', pronunciation: 'RAJ-yuh SUB-huh', definition: 'The upper house (Council of States) of the Parliament of India. It consists of up to 250 members, of whom 238 represent states and Union Territories, and 12 are nominated by the President. It is a permanent body that cannot be dissolved.', usage: 'Money Bills cannot be introduced in the Rajya Sabha and it has limited powers over financial legislation.' },
  { term: 'Lok Sabha', pronunciation: 'LOK SUB-huh', definition: 'The lower house (House of the People) of the Parliament of India. It consists of up to 552 directly elected members representing parliamentary constituencies. It has a maximum term of 5 years and can be dissolved by the President.', usage: 'The government must maintain the confidence of the Lok Sabha to continue in office.' },
  { term: 'Judicial Review', pronunciation: 'joo-DISH-ul rih-VYOO', definition: 'The power of the Supreme Court and High Courts to examine the constitutionality of legislative acts and executive orders. A law can be struck down if it violates any provision of the Constitution.', usage: 'The Supreme Court exercised judicial review and struck down the law as violative of Article 14.' },
  { term: 'Basic Structure Doctrine', pronunciation: 'BAY-sik STRUK-chur DOK-trin', definition: 'A constitutional principle established by the Supreme Court in Kesavananda Bharati (1973) holding that Parliament cannot amend the Constitution in a way that destroys its basic features, such as supremacy of the Constitution, judicial review, federalism, and secularism.', usage: 'The Supreme Court held that the right to equality is part of the basic structure of the Constitution.' },
  { term: 'Ordinance', pronunciation: 'OR-dih-nunts', definition: 'A law promulgated by the President under Article 123 (or by the Governor under Article 213) when Parliament is not in session. It has the same force as an Act of Parliament but must be laid before Parliament and ceases to operate unless approved within six weeks of reassembly.', usage: 'The President promulgated an ordinance to address the urgent economic situation when Parliament was not in session.' },
  { term: 'Prorogation', pronunciation: 'proh-ruh-GAY-shun', definition: 'The termination of a session of Parliament by the President under Article 85. It does not dissolve Parliament; it merely ends the session. Bills pending before Parliament (except Money Bills) lapse on prorogation.', usage: 'The President prorogued Parliament after both Houses had completed the business of the session.' },
];

(function initGlossary() {
  const container = document.getElementById('glossaryContainer');
  const searchInput = document.getElementById('glossarySearch');
  const alphaIndex = document.getElementById('alphaIndex');
  if (!container) return;

  // Sort terms alphabetically
  var sorted = GLOSSARY_TERMS.slice().sort(function (a, b) {
    return a.term.localeCompare(b.term);
  });

  // Build alphabetical index buttons
  var letters = [];
  sorted.forEach(function (t) {
    var l = t.term[0].toUpperCase();
    if (!letters.includes(l)) letters.push(l);
  });

  if (alphaIndex) {
    letters.forEach(function (letter) {
      var btn = document.createElement('button');
      btn.className = 'alpha-btn';
      btn.textContent = letter;
      btn.setAttribute('data-letter', letter);
      btn.addEventListener('click', function () {
        var target = document.getElementById('group-' + letter);
        if (target) {
          var navH = 68;
          var top = target.getBoundingClientRect().top + window.scrollY - navH - 20;
          window.scrollTo({ top: top, behavior: 'smooth' });
        }
        document.querySelectorAll('.alpha-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      });
      alphaIndex.appendChild(btn);
    });
  }

  // Group by letter and render
  function renderGlossary(filter) {
    container.innerHTML = '';
    var groups = {};
    sorted.forEach(function (t) {
      var query = filter ? filter.toLowerCase() : '';
      if (query && !t.term.toLowerCase().includes(query) && !t.definition.toLowerCase().includes(query)) return;
      var l = t.term[0].toUpperCase();
      if (!groups[l]) groups[l] = [];
      groups[l].push(t);
    });

    var groupLetters = Object.keys(groups).sort();
    if (groupLetters.length === 0) {
      container.innerHTML = '<div class="no-results"><h3>No terms found</h3><p>Try a different search term.</p></div>';
      return;
    }

    groupLetters.forEach(function (letter) {
      var groupDiv = document.createElement('div');
      groupDiv.className = 'glossary-group';
      groupDiv.id = 'group-' + letter;

      var letterEl = document.createElement('div');
      letterEl.className = 'glossary-group-letter';
      letterEl.textContent = letter;
      groupDiv.appendChild(letterEl);

      var entriesDiv = document.createElement('div');
      entriesDiv.className = 'glossary-entries';

      groups[letter].forEach(function (t) {
        var entry = document.createElement('div');
        entry.className = 'glossary-entry';
        entry.innerHTML =
          '<div class="glossary-term">' + escapeHtml(t.term) + '</div>' +
          '<div class="glossary-pronunciation">' + escapeHtml(t.pronunciation) + '</div>' +
          '<div class="glossary-definition">' + escapeHtml(t.definition) + '</div>' +
          '<div class="glossary-usage">' + escapeHtml(t.usage) + '</div>';
        entriesDiv.appendChild(entry);
      });

      groupDiv.appendChild(entriesDiv);
      container.appendChild(groupDiv);
    });
  }

  renderGlossary('');

  if (searchInput) {
    searchInput.addEventListener('input', function () {
      renderGlossary(searchInput.value.trim());
    });
    searchInput.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { searchInput.value = ''; renderGlossary(''); }
    });
  }
})();

/* ── Tooltip injection for article pages ── */
function injectVocabTooltips(containerSelector) {
  var container = document.querySelector(containerSelector);
  if (!container) return;

  var termMap = {};
  GLOSSARY_TERMS.forEach(function (t) {
    termMap[t.term.toLowerCase()] = t.definition;
  });

  // Walk text nodes and wrap known terms
  function walkNode(node) {
    if (node.nodeType === 3) { // Text node
      var text = node.textContent;
      var lowerText = text.toLowerCase();
      var replaced = false;
      var terms = Object.keys(termMap).sort(function (a, b) { return b.length - a.length; });

      for (var i = 0; i < terms.length; i++) {
        var term = terms[i];
        var idx = lowerText.indexOf(term);
        if (idx !== -1) {
          var parent = node.parentNode;
          if (parent && parent.classList && parent.classList.contains('vocab-highlight')) continue;

          var before = document.createTextNode(text.slice(0, idx));
          var span = document.createElement('span');
          span.className = 'vocab-highlight';
          span.textContent = text.slice(idx, idx + term.length);

          var tooltip = document.createElement('span');
          tooltip.className = 'vocab-tooltip';
          tooltip.textContent = termMap[term];
          span.appendChild(tooltip);

          var after = document.createTextNode(text.slice(idx + term.length));

          parent.insertBefore(before, node);
          parent.insertBefore(span, node);
          parent.insertBefore(after, node);
          parent.removeChild(node);
          replaced = true;
          break;
        }
      }
      return;
    }

    if (node.nodeType === 1) {
      var skipTags = ['script', 'style', 'a', 'button', 'input', 'textarea', 'code', 'pre'];
      if (skipTags.includes(node.tagName.toLowerCase())) return;
      var children = Array.from(node.childNodes);
      children.forEach(walkNode);
    }
  }

  walkNode(container);
}

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
