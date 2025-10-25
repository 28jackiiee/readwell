# Fix Build Error - Missing File References

## Problem
Xcode project file still references deleted view files, causing build errors.

## Quick Fix (Recommended)

### Option 1: Remove References in Xcode
1. **Open Xcode** and your project
2. In the **Project Navigator** (left sidebar), look for red-colored files (these are missing)
3. **Right-click** each red file
4. Select **"Delete"**
5. Choose **"Remove Reference"** (NOT "Move to Trash")
6. Repeat for all red/missing files:
   - CalendarView.swift
   - WeeklyReviewView.swift
   - ReflectionView.swift
   - SummaryView.swift
   - GuidedTalkView.swift
   - StartView.swift
   - HomeView.swift
   - DailyCheckInView.swift

7. **Clean Build Folder**: Product → Clean Build Folder (Cmd+Shift+K)
8. **Build**: Product → Build (Cmd+B)

### Option 2: Terminal Command
```bash
cd /Users/jackieli/Desktop/readwell

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Open Xcode
open ReadWell.xcodeproj
```

Then follow Option 1 steps to remove references.

## After Fixing

Once you've removed the references:
1. Clean build folder (Cmd+Shift+K)
2. Close and reopen Xcode
3. Build and run (Cmd+R)

## Expected Result
✅ Project builds successfully
✅ No red files in Project Navigator
✅ App runs on simulator/device

