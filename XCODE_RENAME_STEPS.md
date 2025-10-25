# Xcode Project Rename Steps

## App Name Updated to ReadWell

The main app struct is properly named `ReadWellApp` and all references have been updated.

## Additional Manual Steps in Xcode

To complete the renaming, follow these steps in Xcode:

### 1. Update Display Name
1. Open the project in Xcode
2. Select the project in the navigator (top item)
3. Select the **ReadWell** target
4. Go to the **General** tab
5. Verify **Display Name** is set to "ReadWell"

This changes the name that appears under the app icon on the home screen.

### 2. Update Bundle Identifier (Optional but Recommended)
1. In the same **General** tab
2. Find **Bundle Identifier**
3. Verify it's set to `com.yourcompany.ReadWell`

### 3. Rename Scheme (Optional)
1. Click the scheme dropdown (next to play/stop buttons)
2. Select **Manage Schemes**
3. Double-click the scheme
4. Rename to "ReadWell"
5. Click **Close**

### 4. Update Info.plist Values (If needed)
The display name should update automatically, but verify:
1. Open **Info.plist**
2. Check **Bundle display name** is "ReadWell"

### 5. Clean and Rebuild
1. Clean Build Folder: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Delete app from simulator/device
3. Build and Run (Cmd+R)

## What's Already Done ✅

- ✅ Main app struct renamed to `ReadWellApp`
- ✅ All old view files deleted
- ✅ New views use ReadWell terminology
- ✅ README and documentation updated

## What Requires Xcode GUI

These require manual steps in Xcode (cannot be automated):
- Display name change
- Bundle identifier change
- Scheme renaming
- Project file renaming

## Verification

After renaming, verify:
1. App shows as "ReadWell" on home screen
2. No build errors
3. All views load correctly
4. Sample data loads on first launch

---

**Note:** The app is fully functional with the current setup. The Xcode renaming steps are optional but recommended for consistency.

