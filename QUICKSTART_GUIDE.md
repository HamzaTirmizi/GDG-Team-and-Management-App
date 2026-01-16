# 🚀 Quick Start Guide

## Setup Firebase (IMPORTANT - DO THIS FIRST!)

### 1. Apply Firestore Rules
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Copy the rules from `FIREBASE_RULES.md` section 1
5. Click **Publish**

### 2. Apply Storage Rules
1. In Firebase Console, go to **Storage** → **Rules** tab
2. Copy the rules from `FIREBASE_RULES.md` section 2
3. Click **Publish**

### 3. Create Firestore Indexes (Optional but Recommended)
1. Go to **Firestore Database** → **Indexes** tab
2. Create index for `users` collection:
   - Field: `createdAt` (Descending)
   - Click **Create Index**

## Running the App

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Android/iOS
```bash
flutter run
```

### 3. Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## First Time Setup

### Create Super Admin Account

1. **Sign up** with any email/password or Google
2. **Immediately** go to Firebase Console → Firestore Database
3. Find your user document (under `users` collection)
4. Edit the document and change `role` field to `super_admin`
5. **Restart the app**
6. You now have super admin access!

## Features Overview

### 🔴 **Super Admin** (role: `super_admin`)
✅ Create and manage chapters
✅ View all users across the platform  
✅ Assign chapter leads
✅ Full system access

### 🟠 **Chapter Lead** (role: `chapter_lead`)
✅ Create and manage teams in their chapter
✅ Add team leads
✅ View all chapter meetings
✅ Manage chapter members

### 🔵 **Team Lead** (role: `team_lead`)
✅ Add members to their team
✅ Schedule team meetings
✅ Mark attendance
✅ Manage team activities

### 🟢 **Member** (role: `member`)
✅ View team information
✅ See team meetings
✅ Update their profile
✅ Edit semester information

## How to Upload Profile Picture

1. Go to **Profile** tab in any role
2. Click the **camera icon** on the profile picture
3. Choose **Gallery** or **Camera**
4. Image will automatically upload to Firebase Storage
5. Profile picture will appear everywhere in the app

## How to Edit Semester

1. Go to **Profile** tab
2. Find the **Semester** field
3. Click the **edit icon** (pencil)
4. Enter your semester (e.g., "Fall 2026", "Semester 5")
5. Click the **checkmark** to save
6. Semester will update across the app

## Troubleshooting

### ❌ "Permission Denied" Error
**Solution:** Make sure you've applied the Firebase rules from `FIREBASE_RULES.md`

### ❌ Profile Picture Not Uploading
**Solution:** 
1. Check Firebase Storage rules are applied
2. Make sure image is less than 5MB
3. Check internet connection

### ❌ "No users yet" Showing
**Solution:** This is correct! It means there are no users in the database. Sign up to create the first user.

### ❌ Admin Not Showing in Users List
**Solution:** 
1. Make sure the admin user document exists in Firestore
2. Check that the user has the `role` field set correctly
3. The users list now shows ALL users including admins

### ❌ "Error loading chapters" When No Chapters
**Solution:** This issue has been FIXED! Now it will show "No chapters yet" instead of an error.

## Testing the App

### Test as Super Admin
1. Create a chapter (provide chapter name and lead UID)
2. View all users
3. Create multiple chapters

### Test as Chapter Lead
1. Create teams in your chapter
2. Add team leads
3. View all chapter data

### Test as Team Lead
1. Add members to your team
2. Schedule meetings
3. Mark attendance

### Test as Member
1. View your team
2. See upcoming meetings
3. Update your profile

## Security Best Practices

✅ **DO:**
- Keep Firebase config files private
- Use environment variables for sensitive data
- Regularly update dependencies
- Monitor Firebase usage in console

❌ **DON'T:**
- Commit firebase config to public repos
- Share API keys publicly
- Give super admin access to untrusted users
- Ignore Firebase billing alerts

## Support

If you encounter any issues:
1. Check Firebase Console for errors
2. Verify all rules are applied
3. Check app logs in terminal
4. Ensure dependencies are up to date

## Next Steps

1. ✅ Set up Firebase rules
2. ✅ Create super admin account
3. ✅ Test all features
4. 🎉 Deploy your app!

---

**Made with ❤️ for Google Developer Groups**
