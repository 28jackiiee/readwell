# OpenAI Integration Setup

## Overview
MindTalk now uses ChatGPT 4o with structured output to analyze your daily check-in sessions and provide:
- Empathetic summaries
- Core theme identification  
- Emotion detection with intensity levels
- SMART action items
- Personal insights

## API Key Setup

Choose one of these methods to provide your OpenAI API key:

### Method 1: Environment Variable (Recommended)
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
```

### Method 2: Config.plist File
Edit `MindTalk/Utilities/Config.plist` and replace `your_openai_api_key_here` with your actual API key.

### Method 3: .env File
Create a `.env` file in the MindTalk folder:
```
OPENAI_API_KEY=your_actual_api_key_here
```

## Getting an OpenAI API Key

1. Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key and use it in one of the methods above

## How It Works

1. **Record Your Session**: Speak during your 5-minute check-in
2. **AI Processing**: When you click "Finish", ChatGPT 4o analyzes your transcript
3. **Structured Results**: The AI generates:
   - Summary of your session
   - Core themes identified
   - Emotions detected (with intensity 0-10)
   - Actionable items following SMART principles
   - Personal insights and observations

## Features

- **Real-time Processing**: AI analysis happens immediately after your session
- **Structured Output**: Consistent, parseable results every time
- **Privacy**: Your transcript is sent to OpenAI for analysis but not stored there
- **Error Handling**: Graceful fallbacks if the API is unavailable
- **Cost Efficient**: Uses GPT-4o which is optimized for structured output

## Troubleshooting

- **"API key not found"**: Check that your API key is properly set using one of the methods above
- **"Processing failed"**: Check your internet connection and API key validity
- **Rate limits**: OpenAI has usage limits; try again after a few minutes

## Cost Estimate

GPT-4o pricing (as of 2024):
- Input: $2.50 per 1M tokens
- Output: $10.00 per 1M tokens

Typical session analysis:
- ~500 tokens input (your transcript)
- ~300 tokens output (analysis)
- Cost: ~$0.004 per session

For daily use: ~$1.50 per year
