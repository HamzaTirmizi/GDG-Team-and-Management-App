# Firebase Setup Guide

This document outlines what needs to be configured in Firebase Console for this Google Developer Group (GDG) Team Management App.

## Prerequisites

1. Firebase project is already created (Project ID: `gdg-team-and-management-49978`)
2. Firebase Android and iOS apps are registered
3. `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files are in place

## Firebase Services Required

### 1. Firebase Authentication

**Location:** Firebase Console → Authentication → Sign-in method

**Configure the following sign-in providers:**

#### Email/Password
- ✅ Enable Email/Password authentication
- Status: Enabled

#### Google Sign-In
- ✅ Enable Google Sign-In
- Configure OAuth consent screen:
  - Application name: GDG Team Management App
  - Support email: Your email
  - Authorized domains: Add your domain if needed
- Download OAuth 2.0 Client IDs and add to your app

**Setup Steps:**
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password" provider
3. Enable "Google" provider
4. Configure OAuth consent screen in Google Cloud Console
5. Add SHA-1 and SHA-256 fingerprints for Android (if needed)

---

### 2. Cloud Firestore Database

**Location:** Firebase Console → Firestore Database

**Database Structure:**

The app uses the following Firestore collections:

#### Collection: `users`
Each user document contains:
```javascript
{
  name: string,
  studentId: string,
  email: string,
  password: string,  // Hashed/encrypted in production
  role: "member" | "team_lead" | "chapter_lead" | "super_admin",
  semester: string (optional),
  photoUrl: string (optional),
  chapterId: string (optional),
  teamId: string (optional),
  createdAt: timestamp
}
```

#### Collection: `chapters`
Each chapter document contains:
```javascript
{
  name: string,
  chapterLeadId: string (user UID),
  createdAt: timestamp
}
```

**Subcollection under each chapter:** `teams`
Each team document contains:
```javascript
{
  name: string,
  teamLeadId: string (user UID),
  createdAt: timestamp
}
```

**Subcollection under each team:** `members`
Each member document contains:
```javascript
{
  name: string,
  email: string,
  studentId: string,
  role: string,
  addedAt: timestamp
}
```

**Subcollection under each team:** `meetings`
Each meeting document contains:
```javascript
{
  topic: string,
  dateTime: timestamp,
  createdBy: string (user UID),
  createdAt: timestamp
}
```

**Subcollection under each meeting:** `attendance`
Each attendance document contains:
```javascript
{
  status: "Present" | "Absent" | "Late",
  markedAt: timestamp
}
```

**Setup Steps:**
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in production mode" (you can set up rules later)
4. Select a location for your database
5. The collections will be created automatically when the app runs

---

### 3. Firestore Security Rules

**Location:** Firebase Console → Firestore Database → Rules

**Recommended Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      // Super admin can write any user
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Chapters collection
    match /chapters/{chapterId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
      allow update, delete: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId);
      
      // Teams subcollection
      match /teams/{teamId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null && 
          (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId);
        allow update, delete: if request.auth != null && 
          (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId ||
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == teamId);
        
        // Members subcollection
        match /members/{memberId} {
          allow read: if request.auth != null;
          allow write: if request.auth != null && 
            (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId ||
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == teamId);
        }
        
        // Meetings subcollection
        match /meetings/{meetingId} {
          allow read: if request.auth != null;
          allow create: if request.auth != null && 
            (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId ||
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == teamId);
          allow update, delete: if request.auth != null && 
            (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
             resource.data.createdBy == request.auth.uid);
          
          // Attendance subcollection
          match /attendance/{attendanceId} {
            allow read: if request.auth != null;
            allow write: if request.auth != null && 
              (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.chapterId == chapterId ||
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == teamId);
          }
        }
      }
    }
  }
}
```

**Setup Steps:**
1. Go to Firebase Console → Firestore Database → Rules
2. Copy and paste the rules above
3. Click "Publish"
4. **Note:** For development, you can use test mode rules (less secure):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```

---

### 4. Firebase Storage (Optional - for profile photos)

**Location:** Firebase Console → Storage

**Setup Steps:**
1. Go to Firebase Console → Storage
2. Click "Get started"
3. Choose "Start in production mode"
4. Select a location (preferably same as Firestore)
5. Set up security rules for image uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Required Indexes

Some Firestore queries may require composite indexes. Firebase will prompt you to create them when needed, or you can create them manually:

1. **Meetings query (if needed):**
   - Collection: `chapters/{chapterId}/teams/{teamId}/meetings`
   - Fields: `dateTime` (Ascending)

---

## Testing Checklist

After setup, test the following:

- [ ] Email/Password sign up
- [ ] Email/Password login
- [ ] Google Sign-In
- [ ] Create user document in Firestore
- [ ] Create chapter (Super Admin)
- [ ] Create team (Chapter Lead)
- [ ] Add member to team
- [ ] Schedule meeting
- [ ] Mark attendance

---

## First User Setup

To create the first super admin:

1. Sign up with email/password
2. In Firebase Console → Firestore Database → users collection
3. Find the user document
4. Update the `role` field to `"super_admin"`

Alternatively, create a Cloud Function or use Firebase Admin SDK to automatically set the first user as super admin.

---

## Important Notes

1. **Password Storage:** Currently, passwords are stored in plain text in Firestore. For production:
   - Consider using Firebase Authentication only (remove password from Firestore)
   - Or implement proper hashing before storing

2. **Roles:** The app uses 4 roles:
   - `super_admin`: Full access
   - `chapter_lead`: Manages chapters and teams
   - `team_lead`: Manages team members and meetings
   - `member`: Basic access

3. **Security:** Review and customize security rules according to your organization's needs.

4. **Backup:** Set up regular Firestore backups in Firebase Console.

---

## Support

For issues or questions:
- Check Firebase Console logs
- Review Firestore security rules
- Verify authentication configuration
- Check network connectivity

---

**Last Updated:** December 2024


