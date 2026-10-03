const { initializeApp } = require('firebase/app');
const { getFirestore, doc, setDoc, serverTimestamp } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

// Dynamically load config from environment or local uncommitted .env.json
let envConfig = {};
const envJsonPath = path.join(__dirname, '..', '.env.json');
if (fs.existsSync(envJsonPath)) {
  try {
    envConfig = JSON.parse(fs.readFileSync(envJsonPath, 'utf-8'));
  } catch (_) {}
}

const firebaseConfig = {
  apiKey: process.env.FIREBASE_WEB_API_KEY || envConfig.FIREBASE_WEB_API_KEY || '',
  authDomain: (process.env.FIREBASE_PROJECT_ID || envConfig.FIREBASE_PROJECT_ID || 'aura-living-6885e') + '.firebaseapp.com',
  projectId: process.env.FIREBASE_PROJECT_ID || envConfig.FIREBASE_PROJECT_ID || 'aura-living-6885e',
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || envConfig.FIREBASE_STORAGE_BUCKET || 'aura-living-6885e.firebasestorage.app',
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || envConfig.FIREBASE_MESSAGING_SENDER_ID || '668021638019',
  appId: process.env.FIREBASE_WEB_APP_ID || envConfig.FIREBASE_WEB_APP_ID || '',
  measurementId: process.env.FIREBASE_MEASUREMENT_ID || envConfig.FIREBASE_MEASUREMENT_ID || 'G-JRWR1X9SY9'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const users = [
  {
    id: 'f0QD9oDWa3YRxp1TRWbdEaPrhG43',
    name: 'Operations Manager',
    email: 'manager@auraliving.com',
    role: 'storeManager',
    phone: '+8801700000002',
    isGuest: false,
    addresses: []
  },
  {
    id: '2eZ0X0RN0ON0WponpZrcJu3vP8h1',
    name: 'Inventory Staff',
    email: 'staff@auraliving.com',
    role: 'inventoryStaff',
    phone: '+8801700000003',
    isGuest: false,
    addresses: []
  },
  {
    id: 'bZ7vM8xP9qW1rK4tL2nE5yU3iO6a',
    name: 'Operations Admin',
    email: 'admin@demo.aura',
    role: 'admin',
    phone: '+8801700000004',
    isGuest: false,
    addresses: []
  }
];

async function seedUsers() {
  console.log('Seeding authorized users into Firestore...');
  for (const user of users) {
    const userRef = doc(db, 'users', user.id);
    await setDoc(userRef, {
      ...user,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    }, { merge: true });
    console.log(`Seeded user: ${user.name} (${user.email}) -> Role: ${user.role}`);
  }
  console.log('User profiles successfully seeded.');
  process.exit(0);
}

if (require.main === module) {
  seedUsers().catch(err => {
    console.error('Error seeding users:', err);
    process.exit(1);
  });
}

module.exports = { seedUsers };
