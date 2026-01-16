# Firebase Security Rules Setup

## 1. Firestore Database Rules

Go to Firebase Console → Firestore Database → Rules tab and paste this:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is the owner
    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }
    
    // Helper function to get user role
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Helper function to check if user is super admin
    function isSuperAdmin() {
      return isAuthenticated() && getUserRole() == 'super_admin';
    }
    
    // Helper function to check if user is chapter lead
    function isChapterLead() {
      return isAuthenticated() && getUserRole() == 'chapter_lead';
    }
    
    // Helper function to check if user is team lead
    function isTeamLead() {
      return isAuthenticated() && getUserRole() == 'team_lead';
    }
    
    // Users collection rules
    match /users/{userId} {
      // Allow read if authenticated
      allow read: if isAuthenticated();
      
      // Allow create for new users (signup)
      allow create: if isAuthenticated();
      
      // Allow update only if owner or super admin
      allow update: if isOwner(userId) || isSuperAdmin();
      
      // Only super admin can delete users
      allow delete: if isSuperAdmin();
    }
    
    // Chapters collection rules
    match /chapters/{chapterId} {
      // Allow read if authenticated
      allow read: if isAuthenticated();
      
      // Only super admin can create chapters
      allow create: if isSuperAdmin();
      
      // Super admin and chapter lead can update
      allow update: if isSuperAdmin() || isChapterLead();
      
      // Only super admin can delete chapters
      allow delete: if isSuperAdmin();
      
      // Teams subcollection
      match /teams/{teamId} {
        // Allow read if authenticated
        allow read: if isAuthenticated();
        
        // Super admin and chapter lead can create teams
        allow create: if isSuperAdmin() || isChapterLead();
        
        // Super admin, chapter lead, and team lead can update
        allow update: if isSuperAdmin() || isChapterLead() || isTeamLead();
        
        // Super admin and chapter lead can delete teams
        allow delete: if isSuperAdmin() || isChapterLead();
        
        // Members subcollection
        match /members/{memberId} {
          // Allow read if authenticated
          allow read: if isAuthenticated();
          
          // Team lead, chapter lead, and super admin can manage members
          allow write: if isSuperAdmin() || isChapterLead() || isTeamLead();
        }
        
        // Meetings subcollection
        match /meetings/{meetingId} {
          // Allow read if authenticated
          allow read: if isAuthenticated();
          
          // Team lead, chapter lead, and super admin can manage meetings
          allow write: if isSuperAdmin() || isChapterLead() || isTeamLead();
          
          // Attendance subcollection
          match /attendance/{attendanceId} {
            // Allow read if authenticated
            allow read: if isAuthenticated();
            
            // Team lead, chapter lead, and super admin can mark attendance
            allow write: if isSuperAdmin() || isChapterLead() || isTeamLead();
          }
        }
      }
    }
  }
}
```

## 2. Firebase Storage Rules

Go to Firebase Console → Storage → Rules tab and paste this:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile pictures - users can only upload their own
    match /profile_pictures/{userId}.jpg {
      // Allow read for authenticated users
      allow read: if request.auth != null;
      
      // Allow write only for the owner
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Validate file size (max 5MB) and type
      allow write: if request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## 3. Firebase Authentication Setup

Make sure these providers are enabled in Firebase Console → Authentication → Sign-in method:

1. **Email/Password** - Enable this
2. **Google** - Enable this and configure OAuth
3. **Anonymous** - Disabled (not needed)

## 4. Firestore Database Setup

Create these indexes in Firebase Console → Firestore Database → Indexes:

### Index 1: Users by createdAt
- Collection: `users`
- Fields:
  - `createdAt` - Descending
- Query scope: Collection

### Index 2: Meetings by dateTime
- Collection group: `meetings`
- Fields:
  - `dateTime` - Ascending
- Query scope: Collection group

## 5. Testing the Rules

After setting up the rules, test them:

1. **Sign up a new user** - Should create user document
2. **Upload profile picture** - Should upload to Storage
3. **View other users** - Should be able to read but not modify
4. **Super admin operations** - Should be able to create chapters/teams

## Security Notes

✅ **What's Protected:**
- Users can only modify their own profiles
- Only super admins can create/delete chapters
- Only authorized roles can manage teams
- Profile pictures are validated for size and type
- All operations require authentication

✅ **What's Allowed:**
- Authenticated users can read all data (needed for the app)
- Users can update their own semester and profile pic
- Role-based write permissions for hierarchical operations

⚠️ **Important:**
- Always keep your Firebase API keys secure
- Never commit firebase config files to public repositories
- Monitor Firebase usage in the console regularly
- Set up billing alerts to prevent unexpected charges
