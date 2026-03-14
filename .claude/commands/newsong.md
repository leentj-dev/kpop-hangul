K-pop Hangul 앱에 새 곡을 추가하는 커맨드입니다.

## 인자: $ARGUMENTS

## 핵심 규칙
- **lrclib.net에 syncedLyrics가 있는 곡만 추가합니다**
- LRC가 없는 곡은 추가하지 않고 사용자에게 "LRC 없음"으로 알립니다
- 곡 추가 시 반드시 `/syncsong` 커맨드를 사용합니다

## 동작

### `$ARGUMENTS`가 비어있거나 "chart"인 경우:
1. Billboard Korea Hot 100 차트를 WebFetch로 가져옵니다
2. Supabase에서 기존 곡 목록을 확인합니다 (`npx dotenv -e .env.local -- npx tsx scripts/newsong.ts list`)
3. 차트의 각 곡에 대해 `https://lrclib.net/api/search?q={artist}+{title}` 로 LRC 존재 여부를 확인합니다
4. **LRC가 있고** DB에 없는 곡만 목록으로 보여줍니다 (LRC 없는 곡은 ❌ 표시)
5. 사용자에게 어떤 곡을 추가할지 물어봅니다

### `$ARGUMENTS`가 "list"인 경우:
- `npx dotenv -e .env.local -- npx tsx scripts/newsong.ts list` 실행하여 DB의 곡 목록을 보여줍니다

### `$ARGUMENTS`가 곡 이름/아티스트인 경우:
1. `https://lrclib.net/api/search?q={곡 이름}` 에서 syncedLyrics 존재 여부를 확인합니다
2. **syncedLyrics가 없으면**: "이 곡은 LRC 싱크 가사가 없어서 추가할 수 없습니다" 안내 후 중단
3. **syncedLyrics가 있으면**: `/syncsong {곡 이름}`을 실행합니다

### `$ARGUMENTS`가 "all"인 경우:
- 차트에서 LRC가 있는 새 곡을 모두 찾아서 하나씩 `/syncsong`으로 추가합니다

## LRC 확인 방법
```bash
curl -s "https://lrclib.net/api/search?q={artist}+{title}" | node -e "
const chunks=[];
process.stdin.on('data',c=>chunks.push(c));
process.stdin.on('end',()=>{
  const d=JSON.parse(Buffer.concat(chunks).toString());
  const match=d.find(x=>x.syncedLyrics);
  if(match) console.log('LRC_OK|'+match.id+'|'+match.artistName+' - '+match.trackName);
  else console.log('NO_LRC');
});
"
```

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
      "exampleTranslation": "English translation",
      "timestamp": 46
    }
  ]
}
```

## 단어 규칙
- 정확히 20개 단어
- LRC 가사에서 실제로 나오는 한국어 단어만 사용
- 번역은 영어만 (나머지 언어 필드는 빈 문자열)
- timestamp는 lrclib.net의 LRC 타이밍 기반 + MV 오프셋
