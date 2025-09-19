# Health Support Groups Component

This component provides a dedicated platform within the application for users to connect, share experiences, and find peer support for managing specific Non-Communicable Diseases (NCDs).

## Overview & Purpose

The Support Groups component fosters a sense of community, reduces feelings of isolation, and allows for the exchange of practical, lived experiences that complement clinical advice. It focuses initially on Diabetes, Hypertension, and Kidney Disease forums, with an architecture designed to be dynamically configurable for easy addition of new support groups.

## Key Features

- **Browse Groups**: Users can view all available support groups with descriptions
- **View Group Discussions**: Each group has a feed of posts from community members
- **Create Posts**: Users can create new discussion posts within groups
- **Comment & Like**: Users can engage with posts by adding comments and liking them
- **Search**: Ability to search for keywords within a specific group's posts
- **Moderation**: Special privileges for designated moderators to manage content

## Architecture

### Models

- **SupportGroup**: Configurable object defining forum metadata
- **DiscussionPost**: User-generated post content
- **PostComment**: User comments on posts

### Screens

- **SupportGroupsScreen**: Main listing of all available support groups
- **SupportGroupDetailScreen**: View posts within a specific group
- **PostDetailScreen**: View a specific post and its comments
- **CreatePostScreen**: Create a new discussion post
- **EditPostScreen**: Edit an existing post

### Data Management

The component is designed to work with a backend service like Firebase Firestore for real-time updates. The current implementation includes a mock repository that simulates network requests and provides example data.

## Integration

To integrate this component into the main app:

```dart
// Import the support groups feature
import 'package:ncd_app/src/support_groups/support_groups.dart';

// Navigate to the support groups screen
Navigator.of(context).push(SupportGroupsFeature.mainRoute);
```

## Future Enhancements

- Integration with push notifications for comment alerts
- Image attachment support for posts
- User profiles with reputation/badges
- Content filtering options
- Advanced search capabilities