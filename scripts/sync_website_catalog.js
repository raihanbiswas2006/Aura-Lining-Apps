const fs = require('fs');
const path = require('path');
const os = require('os');

const PROJECT_ID = 'aura-living-6885e';
const FIRESTORE_BASE_URL = 'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents';

const config = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json')));
const token = config.tokens.access_token;

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function setDoc(collection, docId, data) {
  const url = FIRESTORE_BASE_URL + '/' + collection + '/' + docId;
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (v !== undefined) fields[k] = toFirestoreValue(v);
  }
  const r = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields })
  });
  if (!r.ok) {
    const err = await r.text();
    throw new Error('Failed to set ' + collection + '/' + docId + ': ' + err);
  }
  console.log('✓ Uploaded ' + collection + '/' + docId);
}

// 1. Categories
const catContent = fs.readFileSync('F:/Git Files/Aura Minimalist E-Commerce Platform/data/categories.ts', 'utf8')
  .replace(/import\s+.*?;/g, '')
  .replace(/export\s+const\s+CATEGORIES:\s*Category\[\]\s*=/, 'module.exports =');
const tmpCat = path.join(__dirname, 'temp_cat.js');
fs.writeFileSync(tmpCat, catContent, 'utf8');
const categories = require(tmpCat);
fs.unlinkSync(tmpCat);

// 2. Products
const prodContent = fs.readFileSync('F:/Git Files/Aura Minimalist E-Commerce Platform/data/products.ts', 'utf8')
  .replace(/import\s+.*?;/g, '')
  .replace(/export\s+const\s+PRODUCTS:\s*Product\[\]\s*=/, 'module.exports =');
const tmpProd = path.join(__dirname, 'temp_prods.js');
fs.writeFileSync(tmpProd, prodContent, 'utf8');
const products = require(tmpProd);
fs.unlinkSync(tmpProd);

async function main() {
  for (const cat of categories) {
    await setDoc('categories', cat.id, {
      ...cat,
      name: cat.title,
      productCount: cat.itemCount || 4
    });
  }
  for (const p of products) {
    const images = p.images.map(img => img.url);
    const stock = p.variants.reduce((sum, v) => sum + (v.stockQuantity || 0), 0);
    await setDoc('products', p.id, {
      ...p,
      name: p.title,
      price: p.discountPrice || p.basePrice,
      images,
      imageUrls: images,
      stock,
      stockQuantity: stock,
      totalStock: stock,
      inStock: stock > 0,
      status: 'Active'
    });
  }
  console.log('All categories and products seeded to Firestore successfully!');
}

main().catch(console.error);
