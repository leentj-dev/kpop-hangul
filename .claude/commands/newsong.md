K-pop Hangul 앱에 새 곡을 추가하는 커맨드입니다.

## 인자: $ARGUMENTS

## 동작

### `$ARGUMENTS`가 비어있거나 "chart"인 경우:
1. Billboard Korea Hot 100 차트를 WebFetch로 가져옵니다
2. Supabase에서 기존 곡 목록을 확인합니다 (`npx dotenv -e .env.local -- npx tsx scripts/newsong.ts list`)
3. 차트에 있지만 DB에 없는 곡을 보여줍니다
4. 사용자에게 어떤 곡을 추가할지 물어봅니다

### `$ARGUMENTS`가 "list"인 경우:
- `npx dotenv -e .env.local -- npx tsx scripts/newsong.ts list` 실행하여 DB의 곡 목록을 보여줍니다

### `$ARGUMENTS`가 곡 이름/아티스트인 경우:
1. YouTube에서 해당 곡의 video ID를 WebSearch로 검색합니다
2. 30개의 한국어 단어를 생성합니다 (7개국어 번역 포함)
3. JSON 파일을 `songs/` 디렉토리에 저장합니다
4. `npx dotenv -e .env.local -- npx tsx scripts/newsong.ts add <file.json>` 실행하여 Supabase에 삽입합니다

### `$ARGUMENTS`가 "all"인 경우:
- 차트에서 새 곡을 모두 찾아서 하나씩 추가합니다

## JSON 파일 형식

songs/ 디렉토리에 저장하는 JSON 형식:
```json
{
  "id": "artist-title-slug",
  "title": "곡 제목",
  "artist": "아티스트",
  "youtubeId": "YouTube_Video_ID",
  "words": [
    {
      "korean": "단어",
      "romanization": "ro-ma-ni-za-tion",
      "english": "English",
      "spanish": "Spanish",
      "portuguese": "Portuguese",
      "indonesian": "Indonesian",
      "japanese": "Japanese",
      "thai": "Thai",
      "french": "French",
      "partOfSpeech": "noun",
      "emoji": "🎵",
      "example": "한국어 예문",
      "exampleTranslation": "English translation"
    }
  ]
}
```

## 단어 생성 규칙
- 정확히 30개 단어
- 노래의 테마/감정에 관련된 일상 한국어 단어
- noun, verb, adjective, adverb 골고루 섞기
- 예문은 자연스러운 한국어로
- 번역은 정확하게 (특히 일본어, 태국어 주의)
- 이모지는 단어 의미에 맞게
