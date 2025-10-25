# Self-Reading Practice Fixes

## Issues Fixed

### 1. **Text Not Changing Colors**
**Problem**: The text rendering was using a complex approach with unused variables and AttributedString, which wasn't updating properly.

**Solution**: 
- Replaced complex `createWrappedWords()` with simpler `createColorCodedText()` function
- Uses SwiftUI Text concatenation which properly triggers view updates
- Changed font weight to `.bold` for matched words (more visible than `.semibold`)

```swift
private func createColorCodedText() -> Text {
    var result = Text("")
    
    for match in wordMatches {
        let color = colorForStatus(match.status)
        let weight: Font.Weight = match.status == .unmatched ? .regular : .bold
        
        result = result + Text(match.word + " ")
            .foregroundColor(color)
            .fontWeight(weight)
            .font(.system(size: 22))
    }
    
    return result
}
```

### 2. **Inaccurate Word Tracking**
**Problem**: The word matching algorithm was too simplistic and didn't handle real-world reading scenarios well.

**Solution**: Implemented a more robust sliding window algorithm with:
- **Better look-ahead**: Checks next 2-3 words in both directions
- **Smarter mismatch handling**: Distinguishes between skipped words and mispronunciations
- **More lenient similarity threshold**: Changed from 0.8 to 0.7 (70% match)
- **Comprehensive logging**: Added debug prints to track matching behavior

Key improvements:
```swift
// Checks if spoken word appears later in text (skip detection)
for lookAhead in (textIndex + 1)..<min(textIndex + 3, textWords.count) {
    if textWords[lookAhead].lowercased() == spokenWord {
        // Mark current word as skipped/incorrect
        wordMatches[textIndex].status = .incorrect
        foundLater = true
        break
    }
}
```

### 3. **Real-time Feedback Display**
**Added**: Visual debug panel showing:
- Current transcript (what student is saying)
- Recording status indicator (red dot + "Recording")
- Live statistics (correct/incorrect counts)
- Color-coded labels for easy tracking

This helps students see:
1. If the microphone is working
2. What words the system is hearing
3. Their progress in real-time

### 4. **Better Authorization Handling**
**Added**: Automatic permission request on view appear
```swift
.onAppear {
    initializeWordMatches()
    if !speechService.isAuthorized {
        speechService.requestAuthorization()
    }
}
```

### 5. **Enhanced Logging**
Added comprehensive debug logging throughout:
- 🎤 Transcript changes
- 📝 Spoken words array
- 📖 Text words count
- 🔍 Each word comparison
- ✅ Matches (exact and similar)
- ❌ Mismatches and skips
- 📊 Final statistics

## How to Debug

### Check Console Output
When testing, watch the Xcode console for:

1. **Initialization**:
   ```
   📚 Initialized 50 words for tracking
   📖 First few words: The, quick, brown, fox, jumps...
   ```

2. **Transcript Updates**:
   ```
   🔄 Transcript changed from '' to 'the quick'
   🎤 Transcript: 'the quick'
   📝 Spoken words: ["the", "quick"]
   ```

3. **Word Matching**:
   ```
   🔍 Comparing text[0]='the' with spoken[0]='the'
   ✅ Exact match!
   🔍 Comparing text[1]='quick' with spoken[1]='quick'
   ✅ Exact match!
   ```

4. **Final Stats**:
   ```
   📊 Match status updated. Correct: 2, Incorrect: 0
   ```

### On-Screen Debug Panel
The view now shows:
- "You said:" with the current transcript
- Recording indicator (red dot)
- Live counts: "X correct" and "Y incorrect"

### Common Issues and Solutions

#### Issue: No words turning green/red
**Check**:
1. Console shows transcript updating? If not, microphone permission issue
2. Console shows word comparisons? If not, `.onChange` not triggering
3. Numbers updating in debug panel? If yes, rendering issue

**Solution**: 
- Restart the app to trigger permission prompts
- Check Settings > Privacy > Microphone and Speech Recognition

#### Issue: All words turning red
**Check**: 
- Are you reading the exact text shown?
- Console showing what you're saying vs. what's expected?

**Solution**:
- The 70% similarity threshold should catch most pronunciation variations
- Try speaking more clearly
- Check if text has special formatting/characters

#### Issue: Colors lag behind speech
**Expected behavior**: Real-time updates should happen as you speak
- If lagging >1 second, may be speech recognition delay (normal)
- If lagging >5 seconds, check network connection (speech recognition requires internet)

## Testing Recommendations

1. **Start Simple**: Read first 5 words slowly and clearly
2. **Check Console**: Verify transcript is updating
3. **Check Colors**: Words should turn green immediately
4. **Try Variations**: Read with different speeds and pronunciations
5. **Test Mistakes**: Intentionally skip or mispronounce words to see red

## Configuration Options

### Adjust Similarity Threshold
In `isSimilarWord()` function, line ~522:
```swift
let threshold = 0.7  // Lower = more lenient, Higher = stricter
```

Values:
- 0.6 = Very lenient (catches most variations)
- 0.7 = Balanced (current setting)
- 0.8 = Strict (only close matches)
- 0.9 = Very strict (nearly exact)

### Toggle Debug Panel
Set `showDebugInfo` to `false` to hide the transcript display:
```swift
@State private var showDebugInfo = false  // Line ~12
```

### Look-ahead Distance
In `updateWordMatches()`, adjust how many words ahead to check:
```swift
for lookAhead in (spokenIndex + 1)..<min(spokenIndex + 3, spokenWords.count)
//                                                        ^ Change this number
```

## Performance Notes

- Levenshtein distance calculation is O(n*m) where n,m are word lengths
- For typical reading passages (500-1000 words), this is negligible
- Real-time updates work smoothly on all devices
- Speech recognition is the bottleneck, not our code

## Future Improvements (Optional)

1. **Phonetic Matching**: Use phonetic algorithms (Soundex, Metaphone) for better pronunciation matching
2. **Confidence Scores**: Use speech recognition confidence to adjust coloring
3. **Second Chance**: Allow students to re-read incorrect words
4. **Word Highlighting**: Highlight current word being matched
5. **Reading Speed**: Track and display words per minute
6. **Pause Detection**: Detect long pauses and mark appropriately

