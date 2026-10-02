const { initializeApp } = require('firebase/app');
const { getFirestore, doc, setDoc, serverTimestamp } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: 'AIzaSyC7ybJVB_xjv5hbNoO5_mAbdeRgRDFFC6Y',
  authDomain: 'aura-living-6885e.firebaseapp.com',
  projectId: 'aura-living-6885e',
  storageBucket: 'aura-living-6885e.firebasestorage.app',
  messagingSenderId: '668021638019',
  appId: '1:668021638019:web:c5dde78b9e796340f3ecb6',
  measurementId: 'G-JRWR1X9SY9'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const users = [
  {
    id: 'PfexgCIR2QWqAedBDMwVDmBml5A2',
    name: 'Super Admin',
    email: 'admin@auraliving.com',
    role: 'superAdmin',
    phone: '+8801700000001',
    isGuest: false,
    addresses: []
  },
  {
    id: 'f0QD9oDWa3YRxp1TRWbdEaPrhG43',
    name: 'Lars Nyström',
    email: 'manager@auraliving.com',
    role: 'storeManager',
    phone: '+8801700000002',
    isGuest: false,
    addresses: []
  },
  {
    id: '2eZ0X0RN0ON0WponpZrcJu3vP8h1',
    name: 'Freja Jensen',
    email: 'staff@auraliving.com',
    role: 'inventoryStaff',
    phone: '+8801700000003',
    isGuest: false,
    addresses: []
  },
  {
    id: 'EW4v8cVH6ucPdmlDoHEKpqbGFjs2',
    name: 'Raihan Biswas',
    email: 'raihanbiswas2006@gmail.com',
    role: 'superAdmin',
    phone: '+8801712345678',
    isGuest: false,
    addresses: []
  },
  {
    id: 'sQqDRULVEJYRhiADoIvcGTndS2A2',
    name: 'Operations Admin',
    email: 'admin@demo.aura',
    role: 'admin',
    phone: '+8801700000004',
    isGuest: false,
    addresses: []
  },
  {
    id: 'rJAc2B46vGNNnEYJMJK5N3rREB12',
    name: 'Nusrat Jahan',
    email: 'nusrat@demo.aura',
    role: 'customer',
    phone: '+8801812345678',
    isGuest: false,
    addresses: [
      {
        id: 'addr-nusrat-1',
        title: 'Home',
        recipientName: 'Nusrat Jahan',
        phoneNumber: '+8801812345678',
        division: 'Chattogram',
        district: 'Chattogram',
        thana: 'Panchlaish',
        streetAddress: 'House 42, Road 3, Nasirabad H/S',
        isDefault: true
      }
    ]
  }
];

async function seedProfiles() {
  console.log('Seeding user profiles into Firestore /users...');
  for (const u of users) {
    await setDoc(doc(db, 'users', u.id), {
      ...u,
      updatedAt: serverTimestamp()
    }, { merge: true });
    console.log('Seeded profile:', u.email, '(' + u.role + ')');
  }
  console.log('Done seeding user profiles!');
  process.exit(0);
}

seedProfiles().catch(err => {
  console.error('Error seeding profiles:', err);
  process.exit(1);
});
