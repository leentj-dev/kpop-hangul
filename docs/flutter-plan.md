# kpop-hangul Flutter 재설계 v1.0 (2026-07-02)

## 근본 (유지)
- 외국인 대상, K-pop 노래 단어로 한글/한국어 학습
- 유튜브 **공식 임베드 플레이어**만 사용 (음원 추출·백그라운드 재생·캡처 금지)
- 가사 전문 인용 금지 — 단어·숙어·제목·유튜브 링크만 (저작권 원칙, CLAUDE.md)
- 콘텐츠 파이프라인: Claude Code가 곡 JSON 생성 → `scripts/newsong.ts` (차트 조회)

## 바뀌는 것
- Next.js 웹 → **Flutter 네이티브 앱** (`app/` 하위 폴더, org: dev.leentj)
- Supabase(삭제됨) → **백엔드 없음**: 곡 JSON을 앱 에셋으로 번들, 추후 정적 JSON URL로 원격 업데이트
- 웹 코드(`src/`)는 앱 완성 후 정리 예정 — 그때까지 참고용 보존

## 데이터
- `scripts/consolidate_songs.py`: `songs/` 74개 파일 → 중복 제거·깨진 파일 제외 → `app/assets/songs/` 56곡 + `manifest.json`
- 곡 선택 규칙: 같은 (artist,title) 그룹에서 타임스탬프 10개 이상인 sync 버전 우선, 없으면 단어 수 최다 버전
- 스킵된 곡(rose-apt 등 4개)은 파이프라인으로 재생성 예정
- **타임스탬프 싱크**: `scripts/sync_timestamps.py` — lrclib.net 공개 싱크 가사 DB에서 타이밍만 추출(가사 텍스트 미저장). lrclib에 있는 곡만 싱크, 없으면 싱크 없이 유지. 단어는 반드시 실제 가사에 등장하는 표면형으로 선정해야 매칭됨. MV 인트로 오프셋은 `--offset 초` 옵션으로 보정.
- 참고: 트로트 이미 9곡 (임영웅 2, 김호중 7) — 시니어·트로트 방향과 접점

## v1 (Phase 1: 이식)
- 피드: 곡 목록 + 검색 (제목/아티스트)
- 곡 상세: 유튜브 플레이어(`youtube_player_iframe`) + 재생 위치 폴링 → 타임스탬프 단어 카드 자동 하이라이트/스크롤
- 단어 카드: 한글 + 자모 분해 + 로마자 + 번역(7개 언어 선택) + 품사 + 예문 + TTS(`flutter_tts`)
- 설정: 언어 선택, 다크 모드 (기본 다크)
- 로컬 저장: `shared_preferences` (언어, 테마)

## v2 (Phase 2: 학습 루프) — v1 검증 후
- 퀴즈(단어→뜻, 뜻→단어), 간격 반복(SRS), 스트릭·알림
- 원격 콘텐츠 업데이트 (정적 manifest URL 폴링)
- 진도·즐겨찾기

## 구조
```
app/lib/
├── main.dart
├── models/song.dart          # Song, WordEntry
├── data/song_repository.dart # 에셋 manifest + 곡 로딩
├── utils/hangul.dart         # 자모 분해 (웹 버전 포팅)
├── screens/feed_screen.dart
├── screens/song_screen.dart  # 플레이어 + 단어 싱크
└── widgets/word_card.dart
```
