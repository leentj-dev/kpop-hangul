K-pop Hangul 앱에 LRC 싱크 가사 기반으로 곡을 추가하는 커맨드입니다.

## 인자: $ARGUMENTS

## 동작

### 1단계: 곡 정보 확인
- `$ARGUMENTS`에서 아티스트명과 곡 제목을 파악합니다
- YouTube에서 해당 곡의 official MV video ID를 WebSearch로 검색합니다

### 2단계: LRC 싱크 가사 가져오기
- `https://lrclib.net/api/search?q={artist}+{title}` 에서 LRC 데이터를 검색합니다
- 검색 결과에서 해당 곡의 ID를 찾습니다
- `https://lrclib.net/api/get/{id}` 에서 syncedLyrics를 가져옵니다
- Bash로 curl + node를 사용하여 LRC 타임스탬프를 파싱합니다:
```
curl -s "https://lrclib.net/api/get/{id}" | node -e "
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const data = JSON.parse(Buffer.concat(chunks).toString());
  const lines = data.syncedLyrics.split('\n');
  lines.forEach(line => {
    const match = line.match(/\[(\d+):(\d+\.\d+)\]\s*(.*)/);
    if (match && match[3].trim()) {
      const secs = parseInt(match[1]) * 60 + parseFloat(match[2]);
      console.log(secs.toFixed(1) + ' | ' + match[3].trim());
    }
  });
});
"
```

### 3단계: MV 오프셋 계산
- 사용자에게 MV에서 첫 가사가 나오는 시간(초)을 물어봅니다
- LRC의 첫 가사 시간과 비교하여 오프셋을 계산합니다
- 오프셋 = MV시간 - LRC시간 - 1초 (1초 앞당김 적용)

### 4단계: 핵심 단어 10개 선택
- LRC 가사에서 가사 라인의 **첫 단어**가 명확한 것들 중 10개를 선택합니다
- 선택 기준:
  - 가사 라인 시작 부분에 해당 단어가 명확하게 들리는 것
  - 곡 전체에 고르게 분포 (앞부분, 중간, 후반부)
  - noun, verb, adjective 골고루
  - 한국어 학습에 유용한 일상 단어 우선

### 5단계: JSON 파일 생성
- 각 단어에 대해 7개국어 번역을 생성합니다
- 타임스탬프 = LRC시간 + 오프셋
- `songs/` 디렉토리에 JSON 파일을 저장합니다

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

### 6단계: DB 삽입
```
npx dotenv -e .env.local -- npx tsx scripts/newsong.ts add songs/<file>.json
```

### 7단계: 확인
- 사용자에게 결과 테이블을 보여줍니다 (MV시간 | 단어 | 뜻)
- 타임스탬프 미세 조정이 필요하면 사용자 피드백을 받아 수정합니다

## 단어 생성 규칙
- 정확히 20개 단어
- 번역은 영어만 (나머지 언어 필드는 빈 문자열)
- 이모지는 단어 의미에 맞게
- 예문은 해당 가사 라인 사용 (저작권상 한 줄 이내)
