import fs from 'fs';
import path from 'path';

// Firebase Project & REST API Configuration
const apiKey = 'AIzaSyC4-KmB5eD8LU3e37Cyns02p7G_fblUm3E';
const projectId = 'home-rental-management-s-22a77';
const jsonPath = path.resolve('scripts/data/location.json');

function jsonToFirestore(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: value.toString() };
    return { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(jsonToFirestore) } };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = jsonToFirestore(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

async function upload() {
  console.log('🚀 Starting upload to Firebase Cloud Firestore...');
  console.log(`📁 Reading location dataset from: ${jsonPath}`);

  if (!fs.existsSync(jsonPath)) {
    console.error(`❌ Error: File not found at ${jsonPath}`);
    return;
  }

  const content = fs.readFileSync(jsonPath, 'utf-8');
  const dataset = JSON.parse(content);
  console.log(`✅ Loaded ${dataset.length} divisions from JSON file.\n`);

  for (const division of dataset) {
    const divisionId = division.id;
    const divisionName = division.name_en || divisionId;
    console.log(`⏳ Uploading division: [${divisionId}] (${divisionName})...`);

    const fields = {};
    for (const [k, v] of Object.entries(division)) {
      fields[k] = jsonToFirestore(v);
    }

    const docUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/locations/${divisionId}?key=${apiKey}`;

    const res = await fetch(docUrl, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields })
    });

    const responseData = await res.json();
    if (res.ok) {
      console.log(`✅ Successfully uploaded "${divisionId}" to Firestore!`);
    } else {
      console.error(`❌ Failed to upload "${divisionId}":`, JSON.stringify(responseData));
    }
  }

  console.log('\n🎉 Finished uploading all divisions to Cloud Firestore!');
}

upload().catch(console.error);

