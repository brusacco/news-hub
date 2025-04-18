// test.js
const jsdom = require("jsdom");
const { JSDOM } = jsdom;
const { Readability } = require("@mozilla/readability");

(async () => {
  const url = process.argv[2];
  let html = "";

  if (!url) {
    console.error("Usage: node test.js <URL>");
    process.exit(1);
  }

  // Read HTML content from stdin
  process.stdin.setEncoding('utf8');
  for await (const chunk of process.stdin) {
    html += chunk;
  }

  const dom = new JSDOM(html, { url });
  const reader = new Readability(dom.window.document);
  const article = reader.parse();

  // Extract siteName and publishedTime from meta tags if available
  let siteName = null;
  let publishedTime = null;
  const metaTags = dom.window.document.getElementsByTagName('meta');
  for (let meta of metaTags) {
    if (meta.getAttribute('property') === 'og:site_name') {
      siteName = meta.getAttribute('content');
    }
    if (meta.getAttribute('property') === 'article:published_time') {
      publishedTime = meta.getAttribute('content');
    }
  }

  // Output JSON with all required fields, plain text only for content
  if (article && article.textContent) {
    console.log(JSON.stringify({
      title: article.title,
      excerpt: article.excerpt,
      siteName: siteName,
      publishedTime: publishedTime,
      textContent: article.textContent.trim()
    }, null, 2));
  } else {
    console.log(JSON.stringify({ error: "No readable text content found." }, null, 2));
  }
})();
