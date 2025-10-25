# OpenAI Integration Setup (Future Enhancement)

## Overview
ReadWell can be enhanced with OpenAI integration for features such as:
- Automated reading difficulty analysis
- Personalized text recommendations
- Custom question generation
- Reading comprehension insights

## API Key Setup

Choose one of these methods to provide your OpenAI API key:

### Method 1: Environment Variable (Recommended)
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
```

### Method 2: Config.plist File
Edit `ReadWell/Utilities/Config.plist` and replace `your_openai_api_key_here` with your actual API key.

### Method 3: .env File
Create a `.env` file in the ReadWell folder:
```
OPENAI_API_KEY=your_actual_api_key_here
```

## Getting an OpenAI API Key

1. Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key and use it in one of the methods above

## Potential Use Cases

1. **Reading Level Analysis**: Analyze text complexity and suggest appropriate grade levels
2. **Question Generation**: Automatically create comprehension questions for new texts
3. **Personalization**: Generate reading recommendations based on student performance
4. **Progress Insights**: AI-powered analysis of student reading patterns

## Features (When Implemented)

- **Real-time Analysis**: AI analysis of reading content and student performance
- **Structured Output**: Consistent, parseable results for data integration
- **Privacy First**: All data handling follows FERPA and COPPA guidelines
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

Typical text analysis:
- ~500 tokens input (text content)
- ~300 tokens output (analysis/questions)
- Cost: ~$0.004 per analysis

For frequent use: Cost varies by feature implementation
