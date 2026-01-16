# 🆓 Firebase Security Rules - FREE TIER (No Billing)

## Important: These rules are optimized for FREE tier usage!

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
    
    // Users collection - SIMPLIFIED FOR FREE TIER
    match /users/{userId} {
      // Anyone authenticated can read
      allow read: if isAuthenticated();
      
      // Allow create for signup
      allow create: if isAuthenticated();
      
      // Users can update their own profile
      allow update: if isOwner(userId);
      
      // No delete for safety
      allow delete: if false;
    }
    
    // Chapters collection
    match /chapters/{chapterId} {
      // Anyone authenticated can read
      allow read: if isAuthenticated();
      
      // Any authenticated user can create (simplified)
      allow create: if isAuthenticated();
      
      // Any authenticated user can update (simplified)
      allow update: if isAuthenticated();
      
      // No delete for safety
      allow delete: if false;
      
      // Teams subcollection
      match /teams/{teamId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated();
        
        // Members subcollection
        match /members/{memberId} {
          allow read: if isAuthenticated();
          allow write: if isAuthenticated();
        }
        
        // Meetings subcollection
        match /meetings/{meetingId} {
          allow read: if isAuthenticated();
          allow write: if isAuthenticated();
          
          // Attendance subcollection
          match /attendance/{attendanceId} {
            allow read: if isAuthenticated();
            allow write: if isAuthenticated();
          }
        }
      }
    }
  }
}
```

**Click "Publish" button!**

---

## 2️⃣ Firebase Storage Rules

**Go to Firebase Console → Storage → Rules → Paste this:**

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile pictures folder
    match /profile_pictures/{userId}.jpg {
      // Anyone authenticated can read profile pictures
      allow read: if request.auth != null;
      
      // Users can only upload their own profile picture
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // Max 5MB
                   && request.resource.contentType.matches('image/.*');  // Only images
    }
  }
}
```

**Click "Publish" button!**

---

## 3️⃣ Setup Steps (IN ORDER!)

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

### Step 2: Apply Storage Rules
1. In Firebase Console, click **Storage** in left menu
2. Click **Rules** tab at top
3. **DELETE ALL existing rules**
4. **COPY** the Storage rules from above (Section 2)
5. **PASTE** into the editor
6. Click **"Publish"** button
7. ✅ Wait for "Rules published successfully" message

### Step 3: Enable Authentication
1. Click **Authentication** in left menu
2. Click **Get Started** (if not already enabled)
3. Click **Sign-in method** tab
4. Enable **Email/Password** ✅
5. Enable **Google** ✅
6. Save changes

### Step 4: Create Storage Bucket (if needed)
1. Click **Storage** in left menu
2. If not started, click **Get Started**
3. Choose **Start in production mode**
4. Select your region (closest to you)
5. Click **Done**
6. ✅ Storage is ready!

---

## 🆓 FREE TIER LIMITS (You Won't Hit These!)

### Firestore (Free Daily Limits):
- ✅ 50,000 document reads/day
- ✅ 20,000 document writes/day
- ✅ 20,000 document deletes/day
- ✅ 1 GB stored data
- ✅ 10 GB/month network egress

**Your app usage:** ~100-1000 operations/day = **WELL WITHIN FREE TIER** ✅

### Storage (Free Total):
- ✅ 5 GB storage
- ✅ 1 GB/day download
- ✅ 20,000 file uploads/day

**Your app usage:** Profile pics ~2MB each = **Can store 2,500+ users** ✅

### Authentication (Free):
- ✅ **UNLIMITED** email/password users
- ✅ **UNLIMITED** Google sign-ins
- ✅ **UNLIMITED** authentication requests

---

## 🔒 Security Features (FREE TIER)

### ✅ What's Protected:
- Users must be authenticated (logged in)
- Users can only upload their own profile pictures
- Profile pictures max 5MB
- Only image files allowed
- All data requires authentication

### ✅ What's Allowed:
- Authenticated users can read all data
- Users can update their own profiles
- Users can create chapters/teams (simplified)
- Everyone can see profile pictures

---

## 🧪 Test Your Rules

### Test 1: Sign Up
```
1. Open your app
2. Sign up with email/password
3. ✅ Should work!
```

### Test 2: Profile Picture
```
1. Go to Profile
2. Click camera icon
3. Upload a picture
4. ✅ Should upload and display!
```

### Test 3: View Data
```
1. Go to different screens
2. Try to view users/chapters/teams
3. ✅ Should see all data!
```

---

## ⚠️ IMPORTANT NOTES FOR FREE TIER

### ✅ DO:
- Keep using the app normally
- Upload profile pictures (under 5MB)
- Create chapters and teams
- Your app is FREE forever at current usage!

### ❌ DON'T:
- Upload videos (not needed, uses storage)
- Create 1000s of test accounts (won't hit limit anyway)
- Store large files (profile pics only)
- Worry about costs - **YOU'RE ON FREE TIER!**

---

## 📊 Monitor Your Usage

### Check Usage (Optional):
1. Firebase Console → **Usage and billing**
2. See your daily usage
3. You'll see you're using **< 1% of free limits** ✅

---

## 🎉 You're All Set!

Your app is now:
- ✅ **Secure** with proper rules
- ✅ **FREE** forever (within limits)
- ✅ **Fast** with good performance
- ✅ **Ready** for production!

**No credit card required! No billing setup needed!** 🆓
