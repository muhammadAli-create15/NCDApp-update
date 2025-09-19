# NCD Mobile App - Messaging and Attachments

## Overview
The NCD Mobile App now supports rich messaging with attachments. Users can send and receive:
- Text messages
- Images
- Videos 
- Documents
- Audio recordings

## Implementation Details

### Storage Setup
The app uses Supabase Storage for file uploads with two primary buckets:
- `message_attachments`: For chat media uploads
- `post_attachments`: For support group post attachments

### Key Components

1. **AttachmentService**
   - Handles file uploads to Supabase Storage
   - Generates unique filenames and metadata
   - Manages file paths based on chat/message IDs
   - Returns URLs for uploaded files

2. **MediaUploadProvider**
   - Provides state management for upload operations
   - Shows upload progress
   - Integrates with AttachmentHandler

3. **AttachmentHandler**
   - UI component for selecting attachment types
   - Manages file picking from camera or gallery
   - Handles pre-upload processing

4. **MessageAttachmentView**
   - Renders different attachment types
   - Supports images, videos, files, and audio
   - Handles different display formats

### How to Use

1. **Sending Attachments:**
   - In any chat, tap the attachment icon (paperclip)
   - Select the type of attachment (photo, video, file, etc.)
   - The attachment will be uploaded to Supabase and sent in the chat

2. **Viewing Attachments:**
   - Images appear directly in the chat
   - Videos show a thumbnail with play button
   - Files show name, size, and download option
   - Audio messages include a simple player

3. **Managing Attachments:**
   - All attachments are securely stored in Supabase
   - Attachment permissions are managed by Postgres RLS policies
   - Only users in a chat can access its attachments

## Technical Implementation

The messaging feature uses a combination of technologies:
- Supabase for real-time database and storage
- Socket.io for real-time messaging
- Local caching for offline support
- Provider pattern for state management

### Supabase Storage RLS Policies

The following RLS policies are in place:

1. **Message Attachments:**
   - Users can only view attachments from chats they're in
   - Users can only upload to chats they're participating in
   - File paths use the format: `chatId/messageId/filename`

2. **Post Attachments:**
   - Public posts are viewable by all users
   - Users can only upload attachments to their own posts
   - File paths use the format: `postId/filename`

## Future Improvements

1. Image compression before upload
2. Better video player integration
3. Audio recording feature
4. File size limits and validation
5. Progress indicators for downloads
