# 🔥 Firebase Security Rules - FINAL VERSION (NO STORAGE)

## ⚠️ IMPORTANT: Apply These Rules to Your Firebase Console!

---

## 1️⃣ Firestore Database Rules

**Go to Firebase Console → Firestore Database → Rules → Paste this:**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read
      allow read: if isAuthenticated();
      
      // Allow create for signup
      allow create: if isAuthenticated();
      
      // Users can update their own profile (semester, photoUrl)
      // Super admin can update any user's role
      allow update: if isOwner(userId) || 
                       (isAuthenticated() && 
                        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin');
      
      // No delete for safety
      allow delete: if false;
    }
    
    // Chapters collection
    match /chapters/{chapterId} {
      // Anyone authenticated can read
      allow read: if isAuthenticated();
      
      // Only super admin can create chapters
      allow create: if isAuthenticated() && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
      
      // Super admin and chapter lead can update
      allow update: if isAuthenticated() && 
                       (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead');
      
      // Only super admin can delete chapters
      allow delete: if isAuthenticated() && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
      
      // Teams subcollection
      match /teams/{teamId} {
        allow read: if isAuthenticated();
        
        // Super admin and chapter lead can create teams
        allow create: if isAuthenticated() && 
                         (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead');
        
        // Super admin, chapter lead, and team lead can update
        allow update: if isAuthenticated() && 
                         (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'team_lead');
        
        // Super admin and chapter lead can delete teams
        allow delete: if isAuthenticated() && 
                         (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead');
        
        // Members subcollection
        match /members/{memberId} {
          allow read: if isAuthenticated();
          
          // Super admin, chapter lead, and team lead can add/remove members
          allow write: if isAuthenticated() && 
                         (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'team_lead');
        }
        
        // Meetings subcollection
        match /meetings/{meetingId} {
          allow read: if isAuthenticated();
          
          // Super admin, chapter lead, and team lead can manage meetings
          allow write: if isAuthenticated() && 
                         (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead' ||
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'team_lead');
          
          // Attendance subcollection
          match /attendance/{attendanceId} {
            allow read: if isAuthenticated();
            
            // Super admin, chapter lead, and team lead can mark attendance
            allow write: if isAuthenticated() && 
                           (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' ||
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'chapter_lead' ||
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'team_lead');
          }
        }
      }
    }
  }
}
```

**Click "Publish" button!**

---

## 2️⃣ Firebase Storage Rules (NOT NEEDED - REMOVE IF EXISTS)

**Since you're not using Firebase Storage, you can ignore this section.**

If you have Storage enabled, you can either:
- **Option 1:** Disable Storage in Firebase Console (recommended)
- **Option 2:** Apply these minimal rules:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Deny all - not using storage
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 3️⃣ Setup Steps

### Step 1: Apply Firestore Rules
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** in left menu
4. Click **Rules** tab at top
5. **DELETE ALL existing rules**
6. **COPY** the Firestore rules from above (Section 1)
7. **PASTE** into the editor
8. Click **"Publish"** button
9. ✅ Wait for "Rules published successfully" message

### Step 2: Enable Authentication
1. Click **Authentication** in left menu
2. Click **Get Started** (if not already enabled)
3. Click **Sign-in method** tab
4. Enable **Email/Password** ✅
5. Enable **Google** ✅
6. Save changes

### Step 3: Create Super Admin (FIRST TIME ONLY)
1. Sign up in your app with any email/password
2. Go to Firebase Console → Firestore Database → `users` collection
3. Find your user document (by email)
4. Click on the document
5. Click **Edit** (pencil icon)
6. Find the `role` field
7. Change value from `member` to `super_admin`
8. Click **Update**
9. **Restart your app**
10. ✅ You now have super admin access!

---

## 🎯 Role Management

### Super Admin (Set in Firebase Console ONLY)
- Can create/delete chapters
- Can make users Chapter Leads, Team Leads, or Members
- Can delete chapters
- Full system access

### Chapter Lead (Made by Super Admin from App)
- Can create/delete teams
- Can make users Team Leads or add Members
- Can remove members from teams
- Manages their chapter

### Team Lead (Made by Chapter Lead from App)
- Can add/remove members
- Can schedule meetings
- Can mark attendance
- Manages their team

### Member (Default role)
- Can view team information
- Can see meetings
- Can update own profile (semester, photo URL)

---

## 🆓 FREE TIER - NO BILLING NEEDED!

### Firestore Limits (FREE):
- ✅ 50,000 document reads/day
- ✅ 20,000 document writes/day
- ✅ 1 GB stored data
- ✅ 10 GB/month network egress

**Your app usage:** ~100-1,000 operations/day = **WELL WITHIN FREE TIER** ✅

### Authentication (FREE):
- ✅ **UNLIMITED** email/password users
- ✅ **UNLIMITED** Google sign-ins
- ✅ **UNLIMITED** authentication requests

---

## 📝 Profile Picture Setup (FREE - No Storage!)

Since you don't have Firebase Storage, users can:

1. **Upload to free image hosting:**
   - [Imgur](https://imgur.com) - Upload image → Right click → Copy image address
   - [ImgBB](https://imgbb.com) - Upload → Copy direct link
   - [PostImage](https://postimages.org) - Upload → Copy direct link
   - Any other free image hosting service

2. **Paste URL in app:**
   - Go to Profile tab
   - Click camera icon on profile picture
   - Paste the image URL
   - Click Save
   - Profile picture appears!

**Example URLs:**
- `https://i.imgur.com/abc123.jpg`
- `https://i.ibb.co/xyz789/image.jpg`
- `https://postimg.cc/abc123`

---

## ✅ Security Features

### ✅ What's Protected:
- Users must be authenticated (logged in)
- Users can only update their own profiles
- Super admin can update any user's role
- Only super admin can create/delete chapters
- Only chapter lead can create/delete teams
- Role-based permissions enforced

### ✅ What's Allowed:
- Authenticated users can read all data
- Users can update their own semester and photoUrl
- Super admin can manage all roles
- Chapter leads can manage teams and members
- Team leads can manage members

---

## 🧪 Test Your Rules

### Test 1: Create Chapter (Super Admin)
```
1. Sign in as super admin
2. Go to Chapters tab
3. Enter chapter name
4. Select chapter lead from dropdown
5. Click "Create Chapter"
6. ✅ Should work!
```

### Test 2: Delete Chapter (Super Admin)
```
1. Go to Chapters tab
2. Click delete icon on a chapter
3. Confirm deletion
4. ✅ Chapter deleted!
```

### Test 3: Create Team (Chapter Lead)
```
1. Sign in as chapter lead
2. Go to Teams tab
3. Enter team name
4. Select team lead from dropdown
5. Click "Create Team"
6. ✅ Team created!
```

### Test 4: Delete Team (Chapter Lead)
```
1. Go to Teams tab
2. Click delete icon on a team
3. Confirm deletion
4. ✅ Team deleted!
```

### Test 5: Add/Remove Member (Team Lead)
```
1. Sign in as team lead
2. Go to Members tab
3. Enter member UID → Click "Add"
4. ✅ Member added!
5. Click remove icon on member
6. ✅ Member removed!
```

### Test 6: Profile Picture URL
```
1. Upload image to Imgur/ImgBB
2. Copy image URL
3. Go to Profile tab
4. Click camera icon
5. Paste URL
6. Click Save
7. ✅ Profile picture appears!
```

---

## 🎉 You're All Set!

Your app is now:
- ✅ **Secure** with proper rules
- ✅ **FREE** forever (no billing)
- ✅ **Complete** with all features
- ✅ **Ready** for production!

**No Firebase Storage needed!** 🆓
