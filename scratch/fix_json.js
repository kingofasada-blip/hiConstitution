const fs = require('fs');

const path = 'c:\\Users\\DeLL\\Desktop\\hiCONSTITUTION\\data\\articles.json';
let data = JSON.parse(fs.readFileSync(path, 'utf8'));

if (data.value && Array.isArray(data.value)) {
    data = data.value;
}

const targetArticles = ['308', '309', '310', '311', '312', '312A', '315', '316', '317', '318', '320', '323'];

data.forEach(part => {
    if (part.partId === 'XIV') {
        if (part.articles) {
            part.articles.forEach(article => {
                if (targetArticles.includes(article.id)) {
                    // Replace digit followed by [ or * that is not preceded by a digit
                    article.text = article.text.replace(/(?<!\d)(\d+)(?=\[|\*)/g, '<sup>$1</sup>');
                }
            });
        }
    }
});

fs.writeFileSync(path, JSON.stringify(data, null, 4), 'utf8');
console.log('JSON fixed and superscripts applied.');
