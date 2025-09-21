Storage buckets and recommended policies

Buckets found in codebase:

- `message_attachments` (used by `AttachmentService` and chat features)
- `post_attachments` (used by support groups / posts)
- `ncd-app-media` (used by `MediaService` for general media uploads)

Recommendations:

- Access: Make these buckets public for fast serving of images/media to clients.
  - If any uploaded content contains sensitive medical data (PDFs, lab results), consider using a private bucket and serving signed URLs instead.
- Folder structure:
  - `message_attachments`: `<chatId>/<messageId>/<uuid>.<ext>`
  - `post_attachments`: `<postId>/<uuid>.<ext>`
  - `ncd-app-media`: `media/<uuid>.<ext>` or `chats/<chatId>/<uuid>.<ext>`
- Policies & security:
  - Supabase Storage access is controlled by bucket-level public flag and by signed URLs.
  - For private buckets, generate signed URLs with an expiry when serving to clients.
  - Use Row Level Security (RLS) on DB tables referencing file paths to ensure users only access their own items.

Operational notes:

- Creating buckets requires the service role (admin) key. Use the script at `scripts/create_buckets.js` or the Supabase dashboard.
- If you need to restrict uploads (e.g., only authenticated users), validate uploads server-side or use Supabase functions.
