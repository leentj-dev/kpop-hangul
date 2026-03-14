"use client";

import { useState, useCallback, useRef, useEffect } from "react";
import { type SongData } from "@/data/songs";
import { useSongs } from "@/hooks/useSongs";

const INITIALS = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];
const MEDIALS = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"];
const FINALS = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];

function decomposeHangul(text: string) {
  return text.split("").map((char) => {
    const code = char.charCodeAt(0);
    if (code < 0xAC00 || code > 0xD7A3) return { char, parts: [char] };
    const offset = code - 0xAC00;
    const initial = INITIALS[Math.floor(offset / (21 * 28))];
    const medial = MEDIALS[Math.floor((offset % (21 * 28)) / 28)];
    const final = FINALS[offset % 28];
    return { char, parts: final ? [initial, medial, final] : [initial, medial] };
  });
}

export default function Home() {
  const { songs, loading } = useSongs();
  const [selectedSong, setSelectedSong] = useState<SongData | null>(null);
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);
  const [isSpeaking, setIsSpeaking] = useState(false);
  type Lang = "english" | "spanish" | "portuguese" | "indonesian" | "japanese" | "thai" | "french";
  const [lang, setLang] = useState<Lang>("english");
  const [searchQuery, setSearchQuery] = useState("");
  const [showSearch, setShowSearch] = useState(false);
  const searchInputRef = useRef<HTMLInputElement>(null);
  const playerContainerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<any>(null);
  const carouselRef = useRef<HTMLDivElement>(null);
  const scrollTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isUserScrolling = useRef(false);
  const wordRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const lastIndexRef = useRef<number>(0);

  // Auto-select first song when songs load
  useEffect(() => {
    if (songs.length > 0 && !selectedSong) {
      setSelectedSong(songs[0]);
    }
  }, [songs, selectedSong]);

  // Search filtering
  const normalizeQuery = (q: string) => q.toLowerCase().replace(/\s/g, "");
  const filteredSongs = searchQuery
    ? songs.filter((s) => {
        const q = normalizeQuery(searchQuery);
        return (
          normalizeQuery(s.title).includes(q) ||
          normalizeQuery(s.artist).includes(q)
        );
      })
    : songs;

  // When search opens, focus input
  useEffect(() => {
    if (showSearch && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [showSearch]);

  const currentSong = selectedSong ?? songs[0];
  const t = currentSong?.theme;

  // Load YouTube IFrame API & create player
  useEffect(() => {
    if (!(window as any).YT) {
      const tag = document.createElement("script");
      tag.src = "https://www.youtube.com/iframe_api";
      document.head.appendChild(tag);
    }

    const createPlayer = () => {
      if (playerRef.current) {
        playerRef.current.destroy();
      }
      playerRef.current = new (window as any).YT.Player(playerContainerRef.current, {
        videoId: currentSong?.youtubeId,
        playerVars: { enablejsapi: 1, rel: 0, fs: 0, modestbranding: 1, disablekb: 0, iv_load_policy: 3 },
        events: {
          onReady: () => {
            // Disable PiP on the iframe
            const iframe = playerRef.current?.getIframe?.();
            if (iframe) {
              iframe.setAttribute("allow", "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope");
              iframe.setAttribute("disablepictureinpicture", "");
            }
          },
        },
      });
    };

    if ((window as any).YT && (window as any).YT.Player) {
      createPlayer();
    } else {
      (window as any).onYouTubeIframeAPIReady = createPlayer;
    }

    return () => {
      if (playerRef.current) {
        playerRef.current.destroy();
        playerRef.current = null;
      }
    };
  }, [currentSong?.youtubeId]);

  const handleSpeak = useCallback((text: string) => {
    setIsSpeaking(true);
    if (typeof window !== "undefined" && window.speechSynthesis) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = "ko-KR";
      utterance.rate = 0.8;
      utterance.onend = () => setIsSpeaking(false);
      utterance.onerror = () => setIsSpeaking(false);
      window.speechSynthesis.speak(utterance);
    }
  }, []);

  const selectWord = useCallback(
    (index: number) => {
      lastIndexRef.current = index;
      setSelectedIndex(index);
    },
    []
  );

  const goNext = useCallback(() => {
    if (selectedIndex !== null && selectedIndex < currentSong.words.length - 1) {
      selectWord(selectedIndex + 1);
    }
  }, [selectedIndex, currentSong.words.length, selectWord]);

  const goPrev = useCallback(() => {
    if (selectedIndex !== null && selectedIndex > 0) {
      selectWord(selectedIndex - 1);
    }
  }, [selectedIndex, selectWord]);

  // Keyboard navigation
  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (selectedIndex === null) return;
      if (e.key === "ArrowRight") goNext();
      if (e.key === "ArrowLeft") goPrev();
      if (e.key === "Escape") setSelectedIndex(null);
    };
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, [selectedIndex, goNext, goPrev]);

  // Set carousel ref + instantly scroll to last position on mount
  const setCarouselRef = useCallback((el: HTMLDivElement | null) => {
    carouselRef.current = el;
    if (el && lastIndexRef.current > 0) {
      const card = el.children[lastIndexRef.current] as HTMLElement;
      if (card) {
        const scrollLeft = card.offsetLeft - (el.offsetWidth - card.offsetWidth) / 2;
        el.scrollTo({ left: scrollLeft, behavior: "instant" });
      }
    }
  }, []);

  // Scroll carousel to selected card + scroll body to show word in grid
  useEffect(() => {
    if (selectedIndex === null) return;

    // Scroll carousel to card (skip if user is swiping the carousel)
    if (carouselRef.current && !isUserScrolling.current) {
      requestAnimationFrame(() => {
        if (!carouselRef.current) return;
        const card = carouselRef.current.children[selectedIndex] as HTMLElement;
        if (card) {
          const scrollLeft = card.offsetLeft - (carouselRef.current.offsetWidth - card.offsetWidth) / 2;
          carouselRef.current.scrollTo({ left: scrollLeft, behavior: "smooth" });
        }
      });
    }

    // Scroll body so the active word in grid is visible
    const wordEl = wordRefs.current[selectedIndex];
    if (wordEl) {
      wordEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }, [selectedIndex]);

  if (!currentSong || !t) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black text-white">
        <p className="animate-pulse text-lg">Loading...</p>
      </div>
    );
  }

  return (
    <div
      className={`min-h-screen bg-gradient-to-b ${t.from} ${t.via} ${t.to} text-white transition-colors duration-700`}
    >
      {/* Sticky Top */}
      <div
        className={`sticky top-0 z-40 bg-gradient-to-b ${t.stickyFrom} ${t.stickyVia} to-transparent pb-3 transition-colors duration-700`}
      >
        <header className="flex items-center justify-between px-4 py-3">
          <h1 className="text-xl font-bold tracking-tight">
            <span className="bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent">
              K-pop Hangul
            </span>
          </h1>
          <div className="flex items-center gap-2">
            <button
              onClick={() => { setShowSearch(!showSearch); if (showSearch) setSearchQuery(""); }}
              className="rounded-lg bg-white/10 p-1.5 text-gray-300 hover:bg-white/20 hover:text-white transition-colors"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
            <select
              value={lang}
              onChange={(e) => setLang(e.target.value as Lang)}
              className="rounded-lg bg-white/10 px-2 py-1 text-xs text-white outline-none"
            >
              <option value="english">🇺🇸 English</option>
              <option value="spanish">🇪🇸 Español</option>
              <option value="portuguese">🇧🇷 Português</option>
              <option value="indonesian">🇮🇩 Indonesia</option>
              <option value="japanese">🇯🇵 日本語</option>
              <option value="thai">🇹🇭 ไทย</option>
              <option value="french">🇫🇷 Français</option>
            </select>
          </div>
        </header>

        {/* Search Bar */}
        {showSearch && (
          <div className="px-4 pb-2">
            <div className="relative">
              <svg className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="곡, 아티스트, 단어 검색..."
                className="w-full rounded-xl bg-white/10 py-2 pl-9 pr-8 text-sm text-white placeholder-gray-400 outline-none ring-1 ring-white/20 focus:ring-white/40 transition-all"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              )}
            </div>
            {searchQuery && (
              <p className="mt-1.5 text-xs text-gray-400">
                {filteredSongs.length}곡 found
              </p>
            )}
          </div>
        )}

        {/* Song Selector */}
        <div className="flex gap-2 overflow-x-auto px-4 pb-3 scrollbar-hide">
          {filteredSongs.map((song) => (
            <button
              key={song.id}
              onClick={() => {
                if (playerRef.current && playerRef.current.stopVideo) {
                  playerRef.current.stopVideo();
                }
                setSelectedSong(song);
                setSelectedIndex(null);
              }}
              className={`shrink-0 overflow-hidden rounded-lg transition-all ${
                currentSong?.id === song.id
                  ? `ring-2 ${t.accentRing} shadow-lg scale-105`
                  : "opacity-70 hover:opacity-100"
              }`}
              style={{ width: 90 }}
            >
              <div className="relative">
                <img
                  src={`https://img.youtube.com/vi/${song.youtubeId}/mqdefault.jpg`}
                  alt={song.title}
                  className="h-[50px] w-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent" />
                <div className="absolute bottom-0 left-0 right-0 px-1.5 pb-1">
                  <p className="text-[9px] text-gray-300 truncate">{song.artist}</p>
                  <p className="text-[10px] font-bold text-white truncate">{song.title}</p>
                </div>
              </div>
            </button>
          ))}
        </div>

        {/* YouTube Embed */}
        <div className="px-4">
          <div className="youtube-no-pip relative mx-auto max-w-2xl overflow-hidden rounded-xl shadow-2xl">
            <div className="relative pt-[56.25%]">
              <div ref={playerContainerRef} className="absolute inset-0 h-full w-full" />
            </div>
          </div>
        </div>

      </div>

      {/* Words Grid */}
      <div className="mt-4 px-4">
        <h3
          className={`mb-3 text-center text-sm font-semibold uppercase tracking-wider ${t.accent}`}
        >
          Words from this song
        </h3>
        <div className="mx-auto grid max-w-2xl grid-cols-2 gap-2 pb-8 sm:grid-cols-3">
          {currentSong.words.map((word, i) => (
            <button
              key={`${word.korean}-${i}`}
              ref={(el) => { wordRefs.current[i] = el; }}
              onClick={() => { handleSpeak(word.korean); selectWord(i); }}
              className={`flex items-center gap-3 rounded-xl px-3 py-3 text-left transition-all ${
                selectedIndex === i
                  ? `${t.accentBg}/30 ring-2 ${t.accentRing}`
                  : "bg-white/5 hover:bg-white/10"
              }`}
            >
              <span className="text-2xl shrink-0">{word.emoji}</span>
              <div className="min-w-0">
                <span className="block text-base font-bold leading-tight">{word.korean}</span>
                <span className="block text-[11px] text-gray-400 truncate">{word[lang]}</span>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Card Carousel Panel */}
      {selectedIndex !== null && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end">
          {/* Full-screen backdrop — blocks touch on background, tap to close popup */}
          <div
            className="absolute inset-0"
            onClick={() => setSelectedIndex(null)}
          />

          {/* Close */}
          <button
            onClick={() => setSelectedIndex(null)}
            className="absolute right-3 top-1 z-10 rounded-full bg-white/10 p-1.5 text-gray-400 hover:bg-white/20 hover:text-white"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>

          {/* Horizontal scroll-snap carousel */}
          <div
            ref={setCarouselRef}
            className="relative flex snap-x snap-mandatory overflow-x-auto pb-6 pt-4 scrollbar-hide"
            style={{ WebkitOverflowScrolling: "touch" }}
            onTouchStart={() => { isUserScrolling.current = true; }}
            onScroll={() => {
              if (scrollTimerRef.current) clearTimeout(scrollTimerRef.current);
              scrollTimerRef.current = setTimeout(() => {
                const el = carouselRef.current;
                if (!el) return;
                const cardWidth = el.firstElementChild ? (el.firstElementChild as HTMLElement).offsetWidth : 280;
                const newIndex = Math.round(el.scrollLeft / cardWidth);
                if (newIndex >= 0 && newIndex < currentSong.words.length) {
                  setSelectedIndex(newIndex);
                }
                isUserScrolling.current = false;
              }, 150);
            }}
          >
            {currentSong.words.map((word, i) => (
              <div
                key={`card-${i}`}
                className="w-[80vw] max-w-[320px] shrink-0 snap-center px-2 first:ml-[10vw] last:mr-[10vw]"
              >
                <div className={`rounded-2xl border p-5 transition-all ${
                  i === selectedIndex
                    ? "border-transparent bg-gray-900 opacity-100"
                    : "border-white/80 bg-gray-900/70 opacity-60 scale-95"
                }`}>
                  {/* Top row */}
                  <div className="flex items-center justify-between">
                    <span className="text-3xl">{word.emoji}</span>
                    <span className={`rounded-full ${t.accentBg}/20 px-2 py-0.5 text-[10px] ${t.accent}`}>
                      {word.partOfSpeech}
                    </span>
                  </div>

                  {/* Korean */}
                  <div className="mt-3 flex items-center gap-2">
                    <span className="text-3xl font-bold cursor-pointer" onClick={(e) => { e.stopPropagation(); handleSpeak(word.korean); }}>{word.korean}</span>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSpeak(word.korean);
                      }}
                      className={`rounded-full p-1.5 transition-colors ${
                        isSpeaking && i === selectedIndex
                          ? `${t.accentBg} text-white animate-pulse`
                          : `${t.accentBg}/20 ${t.accent} hover:${t.accentBg}/40`
                      }`}
                    >
                      <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072M17.95 6.05a8 8 0 010 11.9M6.5 8.788V15.212a.3.3 0 00.173.272l4.5 2.143a.3.3 0 00.427-.272V6.645a.3.3 0 00-.427-.272l-4.5 2.143A.3.3 0 006.5 8.788z" />
                      </svg>
                    </button>
                  </div>

                  <p className={`mt-1 text-sm ${t.accent}`}>[ {word.romanization} ]</p>

                  {/* Hangul decomposition */}
                  <div className="mt-2 flex items-center gap-1 flex-wrap">
                    {decomposeHangul(word.korean).flatMap((s, si) =>
                      s.parts.map((p, pi) => (
                        <button
                          key={`${si}-${pi}`}
                          onClick={(e) => { e.stopPropagation(); handleSpeak(p); }}
                          className={`rounded-lg bg-white/5 px-2.5 py-1.5 text-base font-bold transition-colors hover:bg-white/10 active:bg-white/20 ${pi === 0 ? t.accent : pi === 1 ? "text-green-400" : "text-orange-400"}`}
                        >
                          {p}
                        </button>
                      ))
                    )}
                    <svg className={`h-4 w-4 shrink-0 ${t.accent}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072M17.95 6.05a8 8 0 010 11.9M6.5 8.788V15.212a.3.3 0 00.173.272l4.5 2.143a.3.3 0 00.427-.272V6.645a.3.3 0 00-.427-.272l-4.5 2.143A.3.3 0 006.5 8.788z" />
                    </svg>
                  </div>

                  <p className="mt-2 text-lg text-white">{word[lang]}</p>

                  {/* Example sentence */}
                  <div className="mt-3 rounded-lg bg-white/5 px-3 py-2">
                    <div className="flex items-center gap-1.5">
                      <p className="text-sm font-medium">{word.example}</p>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleSpeak(word.example);
                        }}
                        className={`shrink-0 rounded-full p-1 transition-colors ${t.accentBg}/20 ${t.accent} hover:${t.accentBg}/40`}
                      >
                        <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072M17.95 6.05a8 8 0 010 11.9M6.5 8.788V15.212a.3.3 0 00.173.272l4.5 2.143a.3.3 0 00.427-.272V6.645a.3.3 0 00-.427-.272l-4.5 2.143A.3.3 0 006.5 8.788z" />
                        </svg>
                      </button>
                    </div>
                    <p className="mt-0.5 text-xs text-gray-400">{word.exampleTranslation}</p>
                  </div>

                  <p className="mt-2 text-center text-xs text-gray-500">
                    {i + 1} / {currentSong.words.length}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
