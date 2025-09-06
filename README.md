# MindTalk - Daily Check-in iOS App

A lightweight daily check-in app that guides users through 5-minute voice sessions, automatically generates summaries, tracks emotions, and creates actionable insights.

## Features

### Core Functionality
- **5-minute guided voice sessions** with real-time speech recognition
- **Automatic transcription** using offline Apple Speech Recognition
- **AI-powered summary generation** from voice input
- **Emotion detection and intensity tracking**
- **SMART action generation** (3 actionable items per session)
- **Next-day reflection** on completed actions
- **Streak tracking** with forgiving logic (12-hour grace period)

### User Experience
- **4 intent categories**: School, Health, Relationships, Free Talk
- **Energy level slider** (0-10) before sessions
- **Live captions** with confidence indicators
- **Automatic prompts** every 90 seconds during sessions
- **Beautiful UI** with smooth animations and gradients

### Analytics & Insights
- **Weekly review** with mood trends and completion rates
- **7-day mood sparkline** visualization
- **Action completion tracking** and progress bars
- **Top themes identification** from session content
- **PDF export** for sharing with counselors/coaches

### Notifications & Reminders
- **Daily check-in reminders** at user-set times
- **Action reminders** with smart time parsing
- **Streak encouragement** notifications
- **Weekly review reminders** (Sunday evenings)

## Technical Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Database**: Core Data for local storage
- **Speech Recognition**: Apple Speech Framework (offline)
- **Natural Language Processing**: Apple NaturalLanguage Framework
- **Charts**: iOS 16+ Charts framework with fallback
- **Notifications**: UserNotifications framework
- **PDF Generation**: PDFKit and UIGraphicsPDFRenderer

## Architecture

### MVVM Pattern
- **Models**: Core Data entities (CheckInSession, Emotion, Action, UserSettings)
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI views for each screen
- **Services**: Dedicated services for speech, NLP, notifications, PDF export

### Key Components

1. **SpeechRecognitionService**: Handles real-time voice transcription
2. **NLPService**: Processes transcripts to extract summaries, emotions, and actions
3. **NotificationService**: Manages all local notifications and reminders
4. **PDFExportService**: Generates comprehensive reports
5. **PersistenceController**: Core Data stack management

## Project Structure

```
MindTalk/
├── MindTalkApp.swift              # App entry point
├── ContentView.swift              # Main navigation controller
├── Models/                        # Core Data model files
├── Views/
│   ├── StartView.swift           # Welcome screen with intent selection
│   ├── GuidedTalkView.swift      # 5-minute recording session
│   ├── SummaryView.swift         # Post-session results
│   ├── ReflectionView.swift      # Next-day action review
│   └── WeeklyReviewView.swift    # Analytics and insights
├── ViewModels/
│   └── AppViewModel.swift        # Main app state management
├── Services/
│   ├── PersistenceController.swift
│   ├── SpeechRecognitionService.swift
│   ├── NLPService.swift
│   ├── NotificationService.swift
│   └── PDFExportService.swift
├── Utilities/
│   └── Constants.swift           # App-wide constants and extensions
├── DataModel.xcdatamodeld/       # Core Data model definition
└── Assets.xcassets/              # App icons and colors
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ target device or simulator
- Apple Developer account (for device testing)

### Installation
1. **Clone or copy the project files** into the MindTalk directory
2. **Open MindTalk.xcodeproj** in Xcode
3. **Select your target device** or simulator
4. **Build and run** the project (⌘+R)

### First Launch Setup
1. **Grant microphone permissions** when prompted
2. **Grant speech recognition permissions** when prompted  
3. **Enable notifications** for daily reminders (optional)
4. **Complete your first check-in** to set up the experience

### Testing Features
- **Speech Recognition**: Test with both clear and challenging audio
- **Offline Mode**: Verify speech recognition works without internet
- **Streak Logic**: Test with different check-in patterns
- **Notifications**: Verify reminders appear at set times
- **PDF Export**: Generate and share reports

## Key User Flows

### Daily Check-in (First Time)
1. **Welcome Screen**: Select energy level (0-10) and intent
2. **5-Minute Session**: Speak freely with guided prompts
3. **Auto-Processing**: Summary, emotions, and actions generated
4. **Review Results**: Add reminders for actions if desired

### Next-Day Reflection
1. **Action Review**: Mark yesterday's actions as completed
2. **Quick Reflection**: Optional notes on what helped/hindered
3. **Streak Update**: Continue or reset based on completion
4. **New Session**: Start today's check-in

### Weekly Review (Sundays)
1. **Analytics Dashboard**: View mood trends and completion rates
2. **Top Themes**: See recurring topics from sessions
3. **Next Week Focus**: Personalized recommendations
4. **Export Option**: Generate PDF report for external use

## Privacy & Data

- **Local-Only Storage**: All data stored locally using Core Data
- **No Cloud Sync**: Transcripts and personal data never leave the device
- **Optional Export**: Users can choose to export PDF reports
- **Offline Speech Recognition**: Works without internet connection
- **Secure Processing**: All AI processing happens on-device

## Customization Options

- **Daily reminder time**: Set preferred check-in time
- **Notification preferences**: Enable/disable different notification types
- **Intent categories**: Focus sessions on specific life areas
- **Action reminder timing**: Smart parsing of time preferences

## Performance Considerations

- **Optimized for 5-minute sessions**: Efficient memory and battery usage
- **Background processing**: NLP analysis runs in background thread
- **Cached results**: Avoid reprocessing of completed sessions
- **Progressive loading**: Charts and analytics load incrementally

## Future Enhancements

The current implementation provides a solid MVP foundation. Potential future features:

- **iCloud sync** for multi-device access
- **Apple Watch companion** for quick check-ins
- **Siri integration** for voice-activated sessions
- **Advanced analytics** with machine learning insights
- **Social features** for accountability partners
- **Integration with health apps** (HealthKit, Apple Health)

## Support & Troubleshooting

### Common Issues
- **Microphone not working**: Check Settings > Privacy > Microphone
- **Speech recognition poor**: Ensure quiet environment and clear speech
- **Notifications not appearing**: Check Settings > Notifications > MindTalk
- **App crashes on startup**: Reset and rebuild Core Data stack

### Performance Tips
- **Close other audio apps** during sessions
- **Use wired headphones** for better audio quality
- **Keep app updated** for latest improvements
- **Restart app weekly** to clear temporary data

## License

This is a personal project created for educational and wellness purposes. The code structure and implementation can be used as reference for similar applications.

---

**Built with ❤️ for daily mindfulness and personal growth**
