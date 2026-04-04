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
  QUIZ_CATEGORIES = categories;
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
    icon: '⚖️',
    title: 'Fundamental Rights',
    description: 'Articles 12–35: rights guaranteed to every person in India.',
    difficulty: 'medium',
    questions: [
      {
        q: 'Under which article of the Constitution is the Right to Equality guaranteed?',
        options: ['Article 12', 'Article 14', 'Article 19', 'Article 21'],
        answer: 1,
        explanation: 'Article 14 guarantees the right to equality before law and equal protection of laws. It applies to all persons, not just citizens.'
      },
      {
        q: 'Dr. B.R. Ambedkar described which article as the "heart and soul of the Constitution"?',
        options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
        answer: 3,
        explanation: 'Article 32 — the Right to Constitutional Remedies — was called the "heart and soul of the Constitution" by Dr. Ambedkar because it gives citizens the right to enforce their Fundamental Rights in the Supreme Court.'
      },
      {
        q: 'Article 21 of the Constitution guarantees the right to:',
        options: ['Freedom of religion', 'Right to equality', 'Protection of life and personal liberty', 'Right to constitutional remedies'],
        answer: 2,
        explanation: 'Article 21 states: "No person shall be deprived of his life or personal liberty except according to procedure established by law." The Supreme Court has greatly expanded this right through judicial interpretation.'
      },
      {
        q: 'Which article abolishes untouchability and makes its practice a punishable offence?',
        options: ['Article 15', 'Article 16', 'Article 17', 'Article 18'],
        answer: 2,
        explanation: 'Article 17 abolishes untouchability in all forms. Enforcement of any disability arising from untouchability is an offence punishable under the Protection of Civil Rights Act, 1955.'
      },
      {
        q: 'The right to free and compulsory education for children aged 6 to 14 is guaranteed under:',
        options: ['Article 21', 'Article 21A', 'Article 45', 'Article 51A(k)'],
        answer: 1,
        explanation: 'Article 21A, inserted by the 86th Constitutional Amendment (2002), makes free and compulsory education for children aged 6–14 a Fundamental Right. The Right to Education Act, 2009 implements this right.'
      },
      {
        q: 'Which of the following freedoms is NOT mentioned in Article 19(1)?',
        options: ['Freedom of speech and expression', 'Freedom to form cooperatives', 'Freedom to own property', 'Freedom to move freely throughout India'],
        answer: 2,
        explanation: 'The right to own property was removed from Fundamental Rights by the 44th Amendment (1978) and is now a constitutional right under Article 300A. Article 19(1) contains six freedoms including speech, assembly, associations, movement, residence, and profession. The right to form cooperatives was added by the 97th Amendment (2011).'
      },
      {
        q: 'Against whom can Fundamental Rights be enforced?',
        options: ['Only the Central Government', 'Only State Governments', 'The State as defined in Article 12', 'Only Parliament'],
        answer: 2,
        explanation: 'Fundamental Rights can be enforced against the "State" as defined in Article 12, which includes the Government and Parliament of India, State governments and legislatures, and all local and other authorities within the territory of India or under the control of the Government of India.'
      },
      {
        q: 'The landmark case that transformed the interpretation of Article 21 by requiring procedure to be fair, just, and reasonable was:',
        options: ['A.K. Gopalan v. State of Madras (1950)', 'Maneka Gandhi v. Union of India (1978)', 'Kesavananda Bharati v. State of Kerala (1973)', 'Minerva Mills v. Union of India (1980)'],
        answer: 1,
        explanation: 'Maneka Gandhi v. Union of India (1978) overruled the narrow interpretation in A.K. Gopalan. A 7-judge bench held that procedure under Article 21 must be fair, just, and reasonable, and that Articles 14, 19, and 21 are not mutually exclusive.'
      }
    ]
  },
  {
    id: 'preamble',
    icon: '📜',
    title: 'Preamble',
    description: 'The introductory statement of the Constitution and its key values.',
    difficulty: 'easy',
    questions: [
      {
        q: 'Which words were added to the Preamble by the 42nd Constitutional Amendment (1976)?',
        options: ['Democratic and Republic', 'Socialist and Secular', 'Justice and Fraternity', 'Sovereign and Integrity'],
        answer: 1,
        explanation: 'The 42nd Amendment (1976) added "Socialist," "Secular," and "Integrity" to the Preamble. The original Preamble described India as a "Sovereign Democratic Republic."'
      },
      {
        q: 'According to the Preamble, the Constitution was adopted by the people of India on:',
        options: ['January 26, 1950', 'August 15, 1947', 'November 26, 1949', 'December 9, 1946'],
        answer: 2,
        explanation: 'The Preamble states that the Constituent Assembly adopted, enacted, and gave to themselves the Constitution on November 26, 1949. The Constitution came into force on January 26, 1950.'
      },
      {
        q: 'The Preamble secures to all citizens "Justice" in which three forms?',
        options: ['Legal, Judicial and Executive', 'Social, Economic and Political', 'Constitutional, Legal and Natural', 'Civil, Criminal and Administrative'],
        answer: 1,
        explanation: 'The Preamble resolves to secure Social, Economic, and Political Justice to all citizens. This reflects the comprehensive vision of justice that encompasses all aspects of citizens\' lives.'
      },
      {
        q: 'The Preamble is:',
        options: ['Not a part of the Constitution', 'A part of the Constitution and can be amended', 'Not a part of the Constitution but can be used to interpret it', 'A part of the Constitution but cannot be amended'],
        answer: 1,
        explanation: 'In Kesavananda Bharati v. State of Kerala (1973), the Supreme Court held that the Preamble is a part of the Constitution and can be amended under Article 368, subject to the basic structure doctrine.'
      },
      {
        q: 'India is described as a "Republic" in the Preamble because:',
        options: ['India has no Prime Minister', 'The head of state is elected, not a hereditary monarch', 'India has a written Constitution', 'India has universal adult franchise'],
        answer: 1,
        explanation: 'India is a Republic because its head of state — the President — is an elected official and not a hereditary monarch. This is in contrast to a monarchy like the United Kingdom where the head of state is a hereditary ruler.'
      }
    ]
  },
  {
    id: 'directive-principles',
    icon: '🏛️',
    title: 'Directive Principles',
    description: 'Part IV (Articles 36–51): policy guidelines for the State.',
    difficulty: 'medium',
    questions: [
      {
        q: 'Directive Principles of State Policy are contained in which Part of the Constitution?',
        options: ['Part II', 'Part III', 'Part IV', 'Part IVA'],
        answer: 2,
        explanation: 'Directive Principles of State Policy are contained in Part IV of the Constitution, covering Articles 36 to 51. They are borrowed from the Irish Constitution and provide guidelines for state governance.'
      },
      {
        q: 'Unlike Fundamental Rights, Directive Principles are:',
        options: ['Justiciable', 'Enforceable in courts', 'Non-justiciable', 'Guaranteed to citizens only'],
        answer: 2,
        explanation: 'Directive Principles are non-justiciable, meaning courts cannot enforce them. However, they are "fundamental in the governance of the country" (Article 37) and are important in shaping legislation and policy.'
      },
      {
        q: 'Article 44 of the Constitution directs the State to secure a:',
        options: ['Universal adult franchise', 'Uniform Civil Code', 'Free compulsory education', 'Equal pay for equal work'],
        answer: 1,
        explanation: 'Article 44 directs the State to "endeavour to secure for the citizens a uniform civil code throughout the territory of India." This remains one of the most debated Directive Principles.'
      },
      {
        q: 'The concept of "equal pay for equal work" is enshrined in which article?',
        options: ['Article 39(a)', 'Article 39(d)', 'Article 41', 'Article 43'],
        answer: 1,
        explanation: 'Article 39(d) directs the State to ensure equal pay for equal work for both men and women. While not a Fundamental Right, the Supreme Court has used it to interpret employment laws favorably.'
      },
      {
        q: 'Which article directs the State to organise village panchayats and endow them with powers?',
        options: ['Article 38', 'Article 40', 'Article 43', 'Article 46'],
        answer: 1,
        explanation: 'Article 40 directs the State to organise village panchayats and endow them with such powers and authority as may be necessary to enable them to function as units of self-government. The 73rd Amendment (1992) later gave constitutional status to Panchayati Raj.'
      }
    ]
  },
  {
    id: 'amendments',
    icon: '📝',
    title: 'Constitutional Amendments',
    description: 'Key amendments that shaped India\'s constitutional history.',
    difficulty: 'hard',
    questions: [
      {
        q: 'Which Constitutional Amendment added the Tenth Schedule (Anti-Defection Law) to the Constitution?',
        options: ['42nd Amendment (1976)', '44th Amendment (1978)', '52nd Amendment (1985)', '73rd Amendment (1992)'],
        answer: 2,
        explanation: 'The 52nd Constitutional Amendment Act, 1985 added the Tenth Schedule, which contains the Anti-Defection Law. A member of Parliament or state legislature can be disqualified for defection by voluntarily giving up party membership or voting against the party whip.'
      },
      {
        q: 'The Goods and Services Tax (GST) was introduced by which Constitutional Amendment?',
        options: ['99th Amendment', '100th Amendment', '101st Amendment', '102nd Amendment'],
        answer: 2,
        explanation: 'The Constitution (One Hundred and First Amendment) Act, 2016 introduced GST by inserting Articles 246A, 269A, and 279A. The GST Council was established under Article 279A as a joint forum of the Centre and States. GST came into force on July 1, 2017.'
      },
      {
        q: 'Which amendment is known as the "Mini Constitution" due to the large number of changes it made?',
        options: ['24th Amendment, 1971', '42nd Amendment, 1976', '44th Amendment, 1978', '86th Amendment, 2002'],
        answer: 1,
        explanation: 'The 42nd Amendment Act, 1976 — passed during the Emergency under Indira Gandhi\'s government — is called the "Mini Constitution" because it made the most sweeping changes to the Constitution, amending 53 articles and adding 13 new ones. Many changes were later reversed by the 44th Amendment.'
      },
      {
        q: 'The 10% reservation for Economically Weaker Sections (EWS) was introduced by the:',
        options: ['101st Amendment', '102nd Amendment', '103rd Amendment', '104th Amendment'],
        answer: 2,
        explanation: 'The Constitution (103rd Amendment) Act, 2019 inserted clause (6) in Articles 15 and 16 to provide 10% reservation for EWS in educational institutions and public employment. The Supreme Court upheld it in a 3:2 majority in Janhit Abhiyan v. Union of India (2022).'
      },
      {
        q: 'Which amendment gave constitutional status to Panchayati Raj institutions?',
        options: ['70th Amendment', '71st Amendment', '72nd Amendment', '73rd Amendment'],
        answer: 3,
        explanation: 'The 73rd Constitutional Amendment (1992) added Part IX (Articles 243–243O) and the Eleventh Schedule to the Constitution, giving constitutional status to Panchayati Raj institutions. It mandated gram panchayats, elected bodies at three tiers, and reservations for SC, ST, and women.'
      },
      {
        q: 'By which amendment was the Right to Property removed from the list of Fundamental Rights?',
        options: ['42nd Amendment, 1976', '44th Amendment, 1978', '45th Amendment, 1980', '46th Amendment, 1982'],
        answer: 1,
        explanation: 'The 44th Constitutional Amendment (1978) removed the Right to Property from Fundamental Rights by deleting Articles 19(1)(f) and 31. It was replaced by Article 300A, which provides a constitutional right (not fundamental right) against deprivation of property except by authority of law.'
      }
    ]
  },
  {
    id: 'parliament',
    icon: '🏟️',
    title: 'Parliament & Legislature',
    description: 'Composition, powers, and functioning of Parliament.',
    difficulty: 'medium',
    questions: [
      {
        q: 'A Money Bill can be introduced only in the:',
        options: ['Rajya Sabha', 'Lok Sabha', 'Either House', 'Joint Sitting'],
        answer: 1,
        explanation: 'Under Article 109, a Money Bill (as defined in Article 110) can be introduced only in the Lok Sabha. The Rajya Sabha cannot amend or reject a Money Bill — it can only make recommendations, which the Lok Sabha is free to accept or reject.'
      },
      {
        q: 'The maximum strength of the Rajya Sabha is:',
        options: ['200 members', '230 members', '245 members', '250 members'],
        answer: 3,
        explanation: 'Article 80 provides that the Rajya Sabha shall consist of not more than 250 members — 238 representing States and Union Territories, and 12 nominated by the President for their expertise in art, literature, science, and social service.'
      },
      {
        q: 'A joint sitting of both Houses of Parliament is presided over by:',
        options: ['The President of India', 'The Vice-President', 'The Speaker of the Lok Sabha', 'The Senior-most member'],
        answer: 2,
        explanation: 'Article 118 and the Rules of Procedure provide that a joint sitting (called under Article 108) is presided over by the Speaker of the Lok Sabha. In the Speaker\'s absence, the Deputy Speaker of the Lok Sabha presides.'
      },
      {
        q: 'Which of the following bills CANNOT be referred to a Joint Sitting of Parliament?',
        options: ['An ordinary bill', 'A Constitution Amendment Bill', 'A financial bill other than Money Bill', 'A bill passed by one House and pending in the other'],
        answer: 1,
        explanation: 'Article 108 which provides for joint sittings explicitly excludes Money Bills and Constitution Amendment Bills. Constitution Amendment Bills must be passed separately by each House with the required special majority.'
      },
      {
        q: 'The concept of "zero hour" in Parliament refers to:',
        options: ['Midnight session', 'Time immediately following Question Hour', 'First hour of parliamentary session', 'Emergency session of Parliament'],
        answer: 1,
        explanation: 'Zero Hour is the time immediately following Question Hour (which ends at 12 noon). It is an informal device that allows members to raise matters of urgent public importance without prior notice. The term originated in Indian parliamentary practice.'
      }
    ]
  },
  {
    id: 'emergency',
    icon: '🚨',
    title: 'Emergency Provisions',
    description: 'Articles 352, 356, and 360 — the three types of Emergency.',
    difficulty: 'hard',
    questions: [
      {
        q: 'A National Emergency can be proclaimed under Article 352 on which grounds?',
        options: ['Natural disaster or epidemic', 'War, external aggression, or armed rebellion', 'Failure of constitutional machinery in a state', 'Financial instability threatening India\'s credit'],
        answer: 1,
        explanation: 'Article 352 allows the President to proclaim a National Emergency if satisfied that the security of India or any part is threatened by (1) war, (2) external aggression, or (3) armed rebellion. The word "armed rebellion" replaced "internal disturbance" by the 44th Amendment (1978).'
      },
      {
        q: 'During a National Emergency, the Fundamental Right that CANNOT be suspended is:',
        options: ['Article 19 (Freedoms)', 'Article 21 (Right to Life)', 'Article 22 (Protection against Arrest)', 'Article 32 (Constitutional Remedies)'],
        answer: 1,
        explanation: 'Under Article 358, Article 19 freedoms can be suspended during a National Emergency. Under Article 359, the President can suspend the right to move courts for enforcement of Fundamental Rights (except Articles 20 and 21). Thus, the rights under Articles 20 and 21 cannot be suspended even during a National Emergency.'
      },
      {
        q: 'President\'s Rule (State Emergency) is imposed under which article?',
        options: ['Article 352', 'Article 353', 'Article 355', 'Article 356'],
        answer: 3,
        explanation: 'Article 356 provides for imposition of President\'s Rule when the President is satisfied, on receipt of a Governor\'s report or otherwise, that the governance of a State cannot be carried on in accordance with the Constitution. Parliament must approve it within two months.'
      },
      {
        q: 'A Financial Emergency under Article 360 has been proclaimed in India:',
        options: ['Once, in 1975', 'Twice, in 1962 and 1971', 'Thrice, in 1962, 1971, and 1975', 'Never'],
        answer: 3,
        explanation: 'A Financial Emergency under Article 360 has never been proclaimed in India since the Constitution came into force. The three National Emergencies proclaimed were in 1962 (Chinese aggression), 1971 (Pakistan war), and 1975 (internal disturbance).'
      },
      {
        q: 'The S.R. Bommai case (1994) is significant because the Supreme Court held that:',
        options: ['Financial Emergency can be imposed without Cabinet advice', 'Imposition of President\'s Rule under Article 356 is subject to judicial review', 'National Emergency can be extended indefinitely', 'Parliament cannot revoke a Proclamation of Emergency'],
        answer: 1,
        explanation: 'In S.R. Bommai v. Union of India (1994), a 9-judge bench unanimously held that (1) the imposition of President\'s Rule is subject to judicial review; (2) before imposing President\'s Rule, the Centre must give the state government an opportunity to prove its majority on the floor of the House; and (3) dissolution of the state assembly must not be immediate — it should be kept in abeyance until Parliament approves.'
      }
    ]
  },
  {
    id: 'judiciary',
    icon: '🔏',
    title: 'Judiciary',
    description: 'Supreme Court, High Courts, and the judicial system.',
    difficulty: 'medium',
    questions: [
      {
        q: 'The original jurisdiction of the Supreme Court (Article 131) covers disputes between:',
        options: ['Citizens and the government', 'Two or more states', 'A state and foreign countries', 'Parliament and state legislatures'],
        answer: 1,
        explanation: 'Article 131 confers original jurisdiction on the Supreme Court in disputes between (a) the Government of India and one or more states; (b) the Government of India and states on one side and other states on the other; and (c) two or more states. The dispute must involve a question of law or fact on which the existence or extent of a legal right depends.'
      },
      {
        q: 'The power of the Supreme Court to review its own judgments is called:',
        options: ['Appellate jurisdiction', 'Advisory jurisdiction', 'Review jurisdiction', 'Writ jurisdiction'],
        answer: 2,
        explanation: 'Under Article 137, the Supreme Court has the power to review any judgment pronounced or order made by it. This review jurisdiction is limited — it can be exercised only on grounds mentioned in Order XLVII Rule 1 of the Supreme Court Rules.'
      },
      {
        q: 'Which article empowers the President to seek the advisory opinion of the Supreme Court?',
        options: ['Article 131', 'Article 133', 'Article 143', 'Article 145'],
        answer: 2,
        explanation: 'Article 143 empowers the President to refer to the Supreme Court any question of law or fact of public importance for its advisory opinion. The Supreme Court may give its opinion. This advisory opinion is not binding but carries great authority. The President has sought advisory opinions in several important matters.'
      },
      {
        q: 'The concept of "curative petition" in the Indian Supreme Court was evolved in:',
        options: ['Rupa Ashok Hurra v. Ashok Hurra (2002)', 'Kesavananda Bharati case (1973)', 'Vishaka v. State of Rajasthan (1997)', 'NALSA v. Union of India (2014)'],
        answer: 0,
        explanation: 'In Rupa Ashok Hurra v. Ashok Hurra (2002), the Supreme Court evolved the concept of a "curative petition" — a remedy available after a review petition is dismissed, to prevent miscarriage of justice. It can be filed on grounds of violation of principles of natural justice or bias of a judge.'
      },
      {
        q: 'High Courts in India have the power to issue writs under:',
        options: ['Article 32', 'Article 226', 'Article 227', 'Article 136'],
        answer: 1,
        explanation: 'Article 226 empowers High Courts to issue writs including habeas corpus, mandamus, prohibition, certiorari, and quo warranto for enforcement of Fundamental Rights and for any other purpose. This is broader than the Supreme Court\'s writ jurisdiction under Article 32, which is limited to enforcement of Fundamental Rights only.'
      }
    ]
  },
  {
    id: 'mixed',
    icon: '🎲',
    title: 'Mixed Challenge',
    description: 'A mix of questions from all parts of the Constitution.',
    difficulty: 'mixed',
    questions: [
      {
        q: 'The Constituent Assembly of India held its first session on:',
        options: ['August 15, 1947', 'January 26, 1950', 'December 9, 1946', 'November 26, 1949'],
        answer: 2,
        explanation: 'The Constituent Assembly held its first session on December 9, 1946 in New Delhi. Dr. Sachchidananda Sinha was the temporary (pro-tem) President. Dr. Rajendra Prasad was elected as the permanent President of the Assembly on December 11, 1946.'
      },
      {
        q: 'Which schedule of the Constitution lists the 22 official languages of India?',
        options: ['Sixth Schedule', 'Seventh Schedule', 'Eighth Schedule', 'Ninth Schedule'],
        answer: 2,
        explanation: 'The Eighth Schedule of the Constitution lists the 22 officially recognised languages of India. Originally 14 languages were listed; the current 22 include Assamese, Bengali, Gujarati, Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri, Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu, Urdu, Bodo, and Dogri.'
      },
      {
        q: 'The Basic Structure Doctrine of the Indian Constitution was established in:',
        options: ['Golak Nath v. State of Punjab (1967)', 'Kesavananda Bharati v. State of Kerala (1973)', 'Indira Gandhi v. Raj Narain (1975)', 'Minerva Mills v. Union of India (1980)'],
        answer: 1,
        explanation: 'In Kesavananda Bharati v. State of Kerala (1973), a 13-judge bench of the Supreme Court (by a 7:6 majority) established the Basic Structure Doctrine. It held that while Parliament has wide powers to amend the Constitution under Article 368, it cannot amend or destroy the "basic structure" or essential features of the Constitution.'
      },
      {
        q: 'Which fundamental duty was added by the 86th Constitutional Amendment (2002)?',
        options: ['To protect and improve the natural environment', 'To safeguard public property', 'To provide opportunities for education to children aged 6–14', 'To develop scientific temper'],
        answer: 2,
        explanation: 'The 86th Amendment (2002) added Article 51A(k) — making it the duty of "every citizen who is a parent or guardian to provide opportunities for education to his child or ward between the age of six and fourteen years." This was added alongside Article 21A which made education a Fundamental Right.'
      },
      {
        q: 'The "Doctrine of Colourable Legislation" in constitutional law means:',
        options: ['Legislation that uses colourful language', 'Legislation that is discriminatory on the basis of colour', 'When the legislature does indirectly what it cannot do directly', 'Legislation that violates the Preamble\'s values'],
        answer: 2,
        explanation: 'The Doctrine of Colourable Legislation (also called "fraud on the Constitution") holds that what a legislature cannot do directly, it cannot do indirectly either. If a legislature lacks competence to enact a law directly, it cannot achieve the same result by giving the law a different colour or appearance. The doctrine is used by courts to strike down such legislation.'
      },
      {
        q: 'Article 368 deals with the power of Parliament to amend the Constitution. For most amendments, which majority is required?',
        options: ['Simple majority of members present and voting', 'Absolute majority of total membership', 'Special majority: 2/3 of members present and voting AND absolute majority of total membership', 'Unanimous consent of all members'],
        answer: 2,
        explanation: 'Article 368(2) requires that a Constitution Amendment Bill be passed in each House of Parliament by a special majority: (1) a majority of the total membership of that House, AND (2) a majority of not less than two-thirds of the members of that House present and voting. Some amendments (affecting federal provisions) additionally require ratification by not less than half the state legislatures.'
      }
    ]
  }
];

/* ── Quiz State ── */
var quizState = {
  category: null,
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
function openQuiz(categoryId) {
  var cat = QUIZ_CATEGORIES.find(function (c) { return c.id === categoryId; });
  if (!cat) return;

  quizState.category = cat;
  quizState.questions = shuffleArray(cat.questions.slice());
  quizState.currentIndex = 0;
  quizState.score = 0;
  quizState.answered = false;
  quizState.results = [];

  // Update modal header
  document.getElementById('quizCategoryName').textContent = cat.icon + ' ' + cat.title;

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
  saveHighScore(quizState.category.id, score, total);
}

/* ── Save & Load High Scores ── */
function saveHighScore(categoryId, score, total) {
  try {
    var key = 'hc_hs_' + categoryId;
    var existing = JSON.parse(localStorage.getItem(key) || '0');
    var newScore = Math.max(parseInt(existing) || 0, score);
    localStorage.setItem(key, JSON.stringify(newScore));
  } catch (e) { /* localStorage unavailable */ }
}

function getHighScore(categoryId) {
  try {
    return parseInt(JSON.parse(localStorage.getItem('hc_hs_' + categoryId))) || 0;
  } catch (e) { return 0; }
}

/* ── Restart Quiz ── */
function restartQuiz() {
  openQuiz(quizState.category.id);
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
    var hs = getHighScore(cat.id);
    var card = document.createElement('div');
    card.className = 'category-card';
    card.setAttribute('data-difficulty', cat.difficulty);
    card.setAttribute('tabindex', '0');
    card.setAttribute('role', 'button');
    card.setAttribute('aria-label', 'Start ' + cat.title + ' quiz');

    var diffLabel = cat.difficulty.charAt(0).toUpperCase() + cat.difficulty.slice(1);
    var diffClass = 'diff-' + cat.difficulty;

    card.innerHTML =
      '<div class="category-icon">' + cat.icon + '</div>' +
      '<div class="category-title">' + escapeHtmlQuiz(cat.title) + '</div>' +
      '<p style="font-size:0.82rem;color:var(--muted);line-height:1.5;margin-top:4px;">' + escapeHtmlQuiz(cat.description || '') + '</p>' +
      '<div class="category-meta">' +
        '<span class="q-count">' + cat.questions.length + ' questions' + (hs > 0 ? ' · Best: ' + hs + '/' + cat.questions.length : '') + '</span>' +
        '<span class="difficulty-pill ' + diffClass + '">' + diffLabel + '</span>' +
      '</div>';

    card.addEventListener('click', function () { openQuiz(cat.id); });
    card.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openQuiz(cat.id); }
    });

    grid.appendChild(card);
  });
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
