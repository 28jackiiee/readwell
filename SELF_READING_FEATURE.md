# Self-Reading Practice Feature

## Overview
Added a new self-reading practice feature that uses speech-to-text to assess students' oral reading ability. After listening to a text being read aloud, students now practice reading it themselves with real-time feedback.

## Flow
1. Student selects a text from the library
2. Student listens to the text (existing ReadingView)
3. Student clicks "Done Reading"
4. **NEW**: Student goes to SelfReadingPracticeView to read aloud themselves
5. Student continues to comprehension questions
6. Student sees their progress

## New Features

### SelfReadingPracticeView
Located at: `ReadWell/Views/SelfReadingPracticeView.swift`

#### Key Features:
- **Instructions Screen**: Clear guidance on how the feature works
- **Real-time Speech Recognition**: Uses the existing SpeechRecognitionService
- **Color-coded Feedback**:
  - ✅ **Green**: Words read correctly
  - ❌ **Red**: Words read incorrectly  
  - **Gray**: Words not yet read
- **Progress Bar**: Shows how many words have been read
- **Intelligent Word Matching**:
  - Sequential word-by-word comparison
  - Levenshtein distance algorithm for similarity matching (80% threshold)
  - Handles common pronunciation variations
  - Detects skipped words
- **Completion Summary**:
  - Total words read
  - Correct count (green)
  - Incorrect count (needs practice, shown in orange)
  - Accuracy percentage
  - Option to retry or continue to comprehension

### Updated Data Model
Added to `ReadingSession` entity:
- `oralReadingAccuracy`: Double - Percentage of words read correctly
- `wordsReadCorrectly`: Int16 - Count of correct words
- `wordsReadIncorrectly`: Int16 - Count of incorrect words

### Navigation Updates
- Added `selfReadingPractice` case to `AppView` enum
- Updated `completeReading()` to navigate to self-reading practice instead of directly to comprehension
- Updated `goBack()` navigation to handle the new view in the flow

### Technical Implementation

#### Word Matching Algorithm
```swift
1. Split text into individual words (removing punctuation)
2. Split spoken transcript into words
3. Compare sequentially:
   - Exact match → Green
   - Similar match (Levenshtein distance ≥ 80%) → Green
   - No match → Red
   - Word appears later → Red (skipped word detection)
4. Update UI in real-time as user speaks
```

#### Speech Recognition Integration
- Uses existing `SpeechRecognitionService`
- Requests microphone and speech recognition permissions
- Real-time transcript updates with `.onChange(of: speechService.transcript)`
- Handles recording start/stop/pause states

## Files Modified

1. **New File**: `ReadWell/Views/SelfReadingPracticeView.swift`
   - Main view implementation (600+ lines)

2. **ReadWell/ViewModels/AppViewModel.swift**
   - Added `selfReadingPractice` to `AppView` enum
   - Updated `completeReading()` to navigate to new view
   - Updated `goBack()` for proper navigation

3. **ReadWell/ContentView.swift**
   - Added case for `.selfReadingPractice` in the switch statement

4. **ReadWell/DataModel.xcdatamodeld/DataModel.xcdatamodel/contents**
   - Added `oralReadingAccuracy`, `wordsReadCorrectly`, `wordsReadIncorrectly` attributes

5. **ReadWell.xcodeproj/project.pbxproj**
   - Added SelfReadingPracticeView.swift to build phases
   - Added file references and build file entries

## User Experience

### Before Reading
- Clear instructions with icons
- Visual guide showing green = correct, red = incorrect
- Start button to begin practice

### During Reading
- Progress bar showing completion percentage
- Text display with words changing color in real-time
- Microphone status indicator
- Red recording indicator when listening
- Start/Stop microphone button

### After Reading
- Summary screen with statistics
- "Try Again" option to retry reading
- "Continue to Comprehension" button to proceed
- Visual feedback with color-coded stats

## Permissions Required
- **Microphone**: For recording student's voice
- **Speech Recognition**: For converting speech to text

The app already handles these permissions through `SpeechRecognitionService`.

## Benefits

### For Students
- Immediate feedback on reading accuracy
- Visual reinforcement (color coding)
- Practice safe environment
- Builds confidence through retries
- Gamified learning experience

### For Teachers
- Oral reading accuracy data stored in database
- Track individual student progress
- Identify struggling readers
- Monitor improvement over time
- Data-driven intervention decisions

## Future Enhancements (Optional)

1. **Pronunciation Guidance**: Highlight specific phonemes that were mispronounced
2. **Reading Rate Analysis**: Calculate words per minute
3. **Fluency Metrics**: Measure pauses, hesitations, and prosody
4. **Recording Playback**: Allow students to hear their own reading
5. **Word-level Help**: Tap difficult words for pronunciation help
6. **Difficulty Adaptation**: Suggest texts based on reading level
7. **Progress Badges**: Award achievements for accuracy milestones

## Testing Recommendations

1. Test with various text lengths (short vs. long passages)
2. Test with students of different reading levels
3. Verify microphone permissions handling
4. Test in noisy environments
5. Test with different accents and pronunciations
6. Verify data persistence in Core Data
7. Test retry functionality
8. Test navigation flow (back button handling)

## Notes

- The word matching uses an 80% similarity threshold to be forgiving of minor pronunciation differences
- The algorithm handles punctuation by removing it before comparison
- Real-time updates provide immediate feedback for better learning
- The feature integrates seamlessly with existing reading session tracking
- All reading practice data is stored in Core Data for teacher analytics

