Supabase Storage bucket helper scripts

create_buckets.js
- Purpose: Ensure required storage buckets exist for the mobile app.
- Buckets created: `message_attachments`, `post_attachments`, `ncd-app-media`.

Usage (PowerShell):

```powershell
$env:SUPABASE_URL = 'https://your-project.supabase.co'
$env:SUPABASE_SERVICE_ROLE_KEY = 'your-service-role-key'
node .\scripts\create_buckets.js
```

Notes:
- This script requires the service role key (admin) to create buckets.
- Alternatively you can use the Supabase REST API or the `supabase` CLI to create buckets.

Example REST call (PowerShell + curl):

```powershell
curl -X POST "https://your-project.supabase.co/storage/v1/buckets" `
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" `
  -H "apikey: YOUR_SERVICE_ROLE_KEY" `
  -H "Content-Type: application/json" `
  -d '{"name":"message_attachments","public":true}'
```

Example supabase CLI (if signed-in with correct project):

```powershell
supabase storage bucket create message_attachments --public
```