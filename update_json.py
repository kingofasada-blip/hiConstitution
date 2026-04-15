import json

with open("data/articles.json", "r", encoding="utf-8") as f:
    data = json.load(f)

text_map = {
    "1": """Article 1. Name and territory of the Union.— 
(1) India, that is Bharat, shall be a Union of States. 
1 [(2) The States and the territories thereof shall be as specified in the First Schedule.] (3) The territory of India shall comprise—
(a) the territories of the States; 
2[(b) the Union territories specified in the First Schedule; and] 
(c) such other territories as may be acquired.
Amendment: 
Clause (2) was substituted by the Constitution (Seventh Amendment) Act, 1956, s. 2 (w.e.f. 1-11-1956).
Sub-clause (b) of Clause (3) was substituted by the Constitution (Seventh Amendment) Act, 1956, s. 2 (w.e.f. 1-11-1956).""",

    "2": """Article 2. Admission or establishment of new States.— Parliament may by law admit into the Union, or establish, new States on such terms and conditions as it thinks fit.""",

    "2A": """Article 2A. [Sikkim to be associated with the Union.] — Omitted by the Constitution (Thirty-sixth Amendment) Act, 1975, s. 5 (w.e.f. 26-4-1975).
Amendment: 
This article was originally inserted by the Constitution (Thirty-fifth Amendment) Act, 1974, s. 2 (w.e.f. 1-3-1975), which was subsequently omitted by the 36th Amendment.""",

    "3": """Article 3. Formation of new States and alteration of areas, boundaries or names of existing States.— 
Parliament may by law— 
(a) form a new State by separation of territory from any State or by uniting two or more States or parts of States or by uniting any territory to a part of any State; 
(b) increase the area of any State; 
(c) diminish the area of any State; 
(d) alter the boundaries of any State; 
(e) alter the name of any State: 
1[Provided that no Bill for the purpose shall be introduced in either House of Parliament except on the recommendation of the President and unless, where the proposal contained in the Bill affects the area, boundaries or name of any of the States2***, the Bill has been referred by the President to the Legislature of that State for expressing its views thereon within such period as may be specified in the reference or within such further period as the President may allow and the period so specified or allowed has expired.] 
3[Explanation I.—In this article, in clauses (a) to (e), “State” includes a Union territory, but in the proviso, “State” does not include a Union territory. Explanation II.—The power conferred on Parliament by clause (a) includes the power to form a new State or Union territory by uniting a part of any State or Union territory to any other State or Union territory.]
Amendment: 
Subs. by the Constitution (Fifth Amendment) Act, 1955, s. 2, for the proviso (w.e.f. 24-12-1955). 
The words and letters "specified in Part A or Part B of the First Schedule" omitted by the Constitution (Seventh Amendment) Act, 1956, s. 29 and Sch. (w.e.f. 1-11-1956). 
Ins. by the Constitution (Eighteenth Amendment) Act, 1966, s. 2 (w.e.f. 27-8-1966).""",

    "4": """Article 4. Laws made under articles 2 and 3 to provide for the amendment of the First and the Fourth Schedules and supplemental, incidental and consequential matters.— 
(1) Any law referred to in article 2 or article 3 shall contain such provisions for the amendment of the First Schedule and the Fourth Schedule as may be necessary to give effect to the provisions of the law and may also contain such supplemental, incidental and consequential provisions (including provisions as to representation in Parliament and in the Legislature or Legislatures of the State or States affected by such law) as Parliament may deem necessary. 
(2) No such law as aforesaid shall be deemed to be an amendment of this Constitution for the purposes of article 368."""
}

for part in data:
    if "articles" in part:
        for article in part["articles"]:
            if article.get("id") in text_map:
                article["text"] = text_map[article["id"]]

with open("data/articles.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print("Updated articles.json successfully.")
