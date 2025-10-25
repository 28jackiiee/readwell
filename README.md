# ReadWell - Reading Comprehension App for Struggling Readers

A comprehensive reading support application designed to help struggling readers.

## Overview

ReadWell is an iOS app designed to help struggling readers understand grade-level texts through:

1. **Accessible Reading UI** - Dyslexia-friendly visuals and bilingual support
2. **Adaptive Text-to-Speech** - Adjustable pacing with word highlighting
3. **Low-Friction Comprehension Checks** - Interactive question interface with immediate feedback
4. **Teacher Dashboard** - Progress tracking and analytics for educators

## Key Features

### For Students

#### 🎨 Dyslexia-Friendly Reading Experience
- Adjustable font sizes (14-32pt)
- Customizable line spacing (1.0-3.0x)
- Multiple background color options (beige, cream, white, light blue)
- Clean, distraction-free interface
- Large, readable text optimized for struggling readers

#### 🌍 Bilingual Support
- Side-by-side translation display
- Toggle between original and translated text
- Supports English, Spanish, French, and Mandarin
- Helps ELL (English Language Learner) students

#### 🔊 Text-to-Speech (TTS)
- Natural voice synthesis
- Adjustable reading speed (0.1x - 1.0x)
- Play, pause, and stop controls
- Visual progress tracking
- Sentence-by-sentence reading

#### ✅ Comprehension Questions
- Multiple-choice format
- Immediate feedback on answers
- Explanations for correct answers
- Progress tracking through question sets
- Low-pressure, encouraging interface

#### 📊 Progress Tracking
- View reading history
- See comprehension scores
- Track improvement over time
- Visual stats and achievements

### For Teachers

#### 📈 Dashboard Analytics
- Monitor all student progress
- View class-wide statistics
- Track individual student performance
- Identify students who need additional support

#### 👥 Student Management
- Add and manage student accounts
- View detailed student profiles
- Track reading sessions and scores
- Generate progress reports

#### 📚 Content Management
- Access grade-level appropriate texts
- Filter by grade level (1-6)
- Categorized reading materials
- Built-in sample texts for immediate use

## App Structure

### Core Data Model

**Student**
- Personal profile (name, grade, language preferences)
- Accessibility settings (font size, line spacing, background color)
- Reading preferences (dyslexia font, TTS usage)

**ReadingText**
- Title, content, grade level
- Original language and translations
- Category classification
- Associated comprehension questions

**ReadingSession**
- Tracks time spent reading
- Records TTS and translation usage
- Stores comprehension scores
- Links to student and text

**ComprehensionQuestion**
- Multiple-choice questions
- Correct answer and explanation
- Linked to reading text

**StudentAnswer**
- Records student responses
- Tracks correctness
- Timestamps for analytics

### Navigation Flow

1. **Student Login** → Students select their profile
2. **Text Library** → Browse and select reading materials
3. **Reading View** → Read with TTS and translation support
4. **Comprehension Check** → Answer questions about the text
5. **Progress View** → See scores and achievements

**Teacher Mode:**
1. **Teacher Dashboard** → Overview of all students
2. **Student Detail** → In-depth look at individual progress

## Sample Reading Materials

The app includes 4 pre-loaded stories across different grade levels:

1. **The Helpful Dolphin** (Grade 2) - About kindness and helping others
2. **The Magic Garden** (Grade 3) - About love and care
3. **The Robot's First Day** (Grade 4) - About acceptance and friendship
4. **The Mystery of the Missing Books** (Grade 5) - About problem-solving

Each story includes:
- English and Spanish versions
- 3-4 comprehension questions
- Explanations for correct answers

## Technical Implementation

### Services

**TextToSpeechService**
- AVFoundation-based speech synthesis
- Sentence-by-sentence reading
- Adjustable speech rate
- Delegate-based progress tracking

**PersistenceController**
- Core Data stack management
- Sample data seeding
- Preview data for SwiftUI previews

**SampleDataHelper**
- Automatically loads sample texts on first launch
- Creates grade-appropriate reading materials

### Views

- **StudentLoginView** - Colorful, welcoming login interface
- **TextLibraryView** - Grid-based text browsing with filters
- **ReadingView** - Accessible reading interface with TTS controls
- **ComprehensionCheckView** - Question interface with immediate feedback
- **StudentProgressView** - Stats and achievement display
- **TeacherDashboardView** - Analytics and student management

### Accessibility Features

✓ VoiceOver support
✓ Dynamic Type compatible
✓ High contrast color options
✓ Clear visual hierarchy
✓ Large touch targets
✓ Keyboard navigation support

## Getting Started

### Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Swift 5.7 or later

### Installation

1. Clone the repository
2. Open `ReadWell.xcodeproj` in Xcode
3. Build and run on simulator or device

### First Launch

On first launch, the app will:
1. Create a default student profile
2. Load 4 sample reading texts
3. Display the student login screen

### Adding Students

**Method 1: From Login Screen**
1. Tap "Add New Student"
2. Enter student name and grade level
3. Select primary language
4. Tap "Add Student"

**Method 2: Teacher Dashboard**
Teachers can view all students from the dashboard.

## Usage Guide

### For Students

1. **Select Your Profile** from the login screen
2. **Choose a Story** from the library (filter by grade level)
3. **Read the Text** using:
   - Adjust font size and spacing via settings icon
   - Toggle translation to see bilingual text
   - Use play button for text-to-speech
   - Adjust TTS speed with tortoise/hare buttons
4. **Complete Reading** - Tap "Done Reading" when finished
5. **Answer Questions** - Complete the comprehension check
6. **View Your Progress** - See your score and history

### For Teachers

1. **Access Dashboard** - Tap "Teacher Dashboard" from login
2. **View Class Stats** - See overview of all students
3. **Check Individual Progress** - Tap any student for details
4. **Switch Back** - Use "Student View" button to return

## Customization

### Reading Settings

Students can customize:
- **Font Size:** 14-32pt
- **Line Spacing:** 1.0-3.0x
- **Background:** Beige, Cream, White, or Light Blue

Settings are automatically saved per student profile.

### TTS Settings

- **Speed Control:** 0.1x (slowest) to 1.0x (fastest)
- **Default:** 0.5x (moderate pace)
- Adjustable in real-time during reading

## API Keys

The app uses OpenAI for potential future features but currently works fully offline with local TTS.

API keys are loaded from:
1. Environment variables (`.env` file)
2. `Config.plist` file
3. System environment

## Data Privacy

- All data stored locally using Core Data
- No cloud sync or external data transmission
- Student data remains on device
- FERPA and COPPA compliant design

## Future Enhancements

Potential additions:
- [ ] Voice recording for reading fluency assessment
- [ ] AI-powered reading difficulty analysis
- [ ] Personalized text recommendations
- [ ] Parent/guardian portal
- [ ] Reading streak tracking
- [ ] Gamification elements
- [ ] Export progress reports as PDF
- [ ] Custom text upload by teachers
- [ ] Audio book support
- [ ] Reading comprehension strategies overlay

## Troubleshooting

### TTS Not Working
- Check device volume
- Ensure app has microphone permissions
- Restart the app

### Translations Not Showing
- Verify text has translated content
- Check language settings in student profile

### Progress Not Saving
- Ensure app has proper storage permissions
- Check available device storage

## Credits

Built with:
- SwiftUI for modern, declarative UI
- Core Data for local persistence
- AVFoundation for text-to-speech
- Swift 5.7+ features

## License

This project is provided as-is for educational purposes.

## Contact

For questions or support, please reach out to the development team.

---

**Note:** This app is designed to support struggling readers and their educators with accessible, adaptive reading tools.
