/*
  create_buckets.js

  Usage:
    - Set environment variables `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
      Example (PowerShell):
        $env:SUPABASE_URL = 'https://your-project.supabase.co';
        $env:SUPABASE_SERVICE_ROLE_KEY = 'your-service-role-key';
        node .\scripts\create_buckets.js

  This script lists existing buckets and creates any missing buckets
  used by the Flutter app: message_attachments, post_attachments, ncd-app-media.
  It must be run with the service role key (admin key) because creating buckets
  requires elevated privileges.
*/

const https = require('https');

function envOrThrow(name) {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing environment variable ${name}`);
    process.exit(1);
  }
  return v;
}

const SUPABASE_URL = envOrThrow('SUPABASE_URL').replace(/\/$/, '');
const SERVICE_ROLE = envOrThrow('SUPABASE_SERVICE_ROLE_KEY');

const bucketsToEnsure = [
  { name: 'message_attachments', public: true },
  { name: 'post_attachments', public: true },
  { name: 'ncd-app-media', public: true },
];

async function request(method, path, body) {
  const url = new URL(path, SUPABASE_URL);
  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${SERVICE_ROLE}`,
      'apikey': SERVICE_ROLE,
      'Content-Type': 'application/json',
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        const status = res.statusCode || 0;
        let parsed = null;
        try { parsed = data ? JSON.parse(data) : null; } catch (e) { parsed = data; }
        if (status >= 200 && status < 300) return resolve({ status, body: parsed });
        return reject({ status, body: parsed });
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function listBuckets() {
  const path = '/storage/v1/buckets';
  const res = await request('GET', path);
  return res.body || [];
}

async function createBucket(name, isPublic) {
  const path = '/storage/v1/buckets';
  const body = { name, public: !!isPublic };
  return await request('POST', path, body);
}

(async () => {
  try {
    console.log('Listing existing buckets...');
    const existing = await listBuckets();
    const existingNames = existing.map((b) => b.name);

    for (const b of bucketsToEnsure) {
      if (existingNames.includes(b.name)) {
        console.log(`Bucket exists: ${b.name}`);
      } else {
        try {
          console.log(`Creating bucket: ${b.name} (public=${b.public})`);
          const resp = await createBucket(b.name, b.public);
          console.log(`Created bucket ${b.name}:`, resp.body || resp.status);
        } catch (err) {
          console.error(`Failed to create bucket ${b.name}:`, err);
        }
      }
    }

    console.log('Done.');
  } catch (e) {
    console.error('Error while ensuring buckets:', e);
    process.exit(1);
  }
})();
