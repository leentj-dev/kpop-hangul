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
            const iframe = playerRef.current?.getIframe?.();
            if (iframe) {
              iframe.setAttribute("allow", "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope");
              iframe.removeAttribute("allowfullscreen");
              iframe.setAttribute("disablepictureinpicture", "true");
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

  const LANG_CODES: Record<string, string> = {
    korean: "ko-KR", english: "en-US", spanish: "es-ES", portuguese: "pt-BR",
    indonesian: "id-ID", japanese: "ja-JP", thai: "th-TH", french: "fr-FR",
  };

  const handleSpeak = useCallback((text: string, isWord = false, speechLang = "ko-KR") => {
    if (isWord) setIsSpeaking(true);
    if (typeof window !== "undefined" && window.speechSynthesis) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = speechLang;
      utterance.rate = 0.8;
      utterance.onend = () => setIsSpeaking(false);
      utterance.onerror = () => setIsSpeaking(false);
      window.speechSynthesis.speak(utterance);
    }
  }, []);

  // Get timestamp: use word's timestamp field if available, otherwise evenly distribute
  const getTimestamp = useCallback((index: number) => {
    const word = currentSong?.words[index];
    if (word?.timestamp != null) return word.timestamp;
    const duration = playerRef.current?.getDuration?.() || 210;
    const interval = duration / (currentSong?.words.length || 30);
    return Math.floor(index * interval);
  }, [currentSong?.words]);

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
  };

  const seekToWord = useCallback((index: number) => {
    const time = getTimestamp(index);
    if (playerRef.current?.seekTo) {
      playerRef.current.seekTo(time, true);
      if (playerRef.current.getPlayerState?.() !== 1) {
        playerRef.current.playVideo?.();
      }
    }
  }, [getTimestamp]);

  const selectWord = useCallback(
    (index: number) => {
      lastIndexRef.current = index;
      setSelectedIndex(index);
      seekToWord(index);
    },
    [seekToWord]
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

  // Lock body scroll when popup is open
  useEffect(() => {
    if (selectedIndex !== null) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [selectedIndex]);

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
      <div className="flex min-h-screen items-center justify-center bg-white">
        <p className="animate-pulse text-lg text-gray-400">Loading...</p>
      </div>
    );
  }

  return (
    <div
      className="min-h-screen bg-white text-gray-900 transition-colors duration-700"
    >
      {/* Sticky Top */}
      <div className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-gray-200 pb-3">
        <header className="flex items-center justify-between px-4 py-3">
          <h1 className="text-xl font-bold tracking-tight">
            <span className="bg-gradient-to-r from-amber-500 via-pink-500 to-purple-600 bg-clip-text text-transparent">
              K-pop Hangul
            </span>
          </h1>
          <div className="flex items-center gap-2">
            <button
              onClick={() => { setShowSearch(!showSearch); if (showSearch) setSearchQuery(""); }}
              className="rounded-full p-2 text-gray-600 hover:bg-gray-100 transition-colors"
            >
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
            <select
              value={lang}
              onChange={(e) => setLang(e.target.value as Lang)}
              className="rounded-lg border border-gray-200 bg-white px-2 py-1 text-xs text-gray-700 outline-none focus:border-gray-400"
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
                placeholder="Search songs, artists..."
                className="w-full rounded-xl bg-gray-100 py-2 pl-9 pr-8 text-sm text-gray-900 placeholder-gray-400 outline-none focus:bg-gray-50 focus:ring-1 focus:ring-gray-300 transition-all"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              )}
            </div>
            {searchQuery && (
              <p className="mt-1.5 text-xs text-gray-400">
                {filteredSongs.length} results
              </p>
            )}
          </div>
        )}

        {/* Song Selector - Instagram Stories style */}
        <div className="flex gap-3 overflow-x-auto px-4 pt-1 pb-2 scrollbar-hide">
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
              className="shrink-0 flex flex-col items-center gap-1"
              style={{ width: 68 }}
            >
              <div className={`rounded-full p-[2px] ${
                currentSong?.id === song.id
                  ? "bg-gradient-to-br from-amber-500 via-pink-500 to-purple-600"
                  : "bg-gray-200"
              }`}>
                <img
                  src={`https://img.youtube.com/vi/${song.youtubeId}/mqdefault.jpg`}
                  alt={song.title}
                  className="h-[58px] w-[58px] rounded-full object-cover border-2 border-white"
                />
              </div>
              <p className="text-[10px] text-gray-600 truncate w-full text-center leading-tight">{song.title}</p>
            </button>
          ))}
        </div>

        {/* YouTube Embed */}
        <div className="px-4">
          <div className="youtube-no-pip relative mx-auto max-w-2xl overflow-hidden rounded-lg border border-gray-200">
            <div className="relative pt-[56.25%]">
              <div ref={playerContainerRef} className="absolute inset-0 h-full w-full" />
            </div>
          </div>
        </div>

      </div>

      {/* Words Grid */}
      <div className="mt-4 px-4">
        <div className="mx-auto grid max-w-2xl grid-cols-2 gap-2 pb-8 sm:grid-cols-3">
          {currentSong.words.map((word, i) => (
            <button
              key={`${word.korean}-${i}`}
              ref={(el) => { wordRefs.current[i] = el; }}
              onClick={() => { selectWord(i); }}
              className={`flex items-center gap-3 rounded-xl border px-3 py-3 text-left transition-all ${
                selectedIndex === i
                  ? "border-gray-400 bg-gray-50 shadow-sm"
                  : "border-gray-100 bg-white hover:bg-gray-50"
              }`}
            >
              <span className="text-2xl shrink-0">{word.emoji}</span>
              <div className="min-w-0 flex-1">
                <span className="block text-base font-bold leading-tight text-gray-900">{word.korean}</span>
                <span className="block text-[11px] text-gray-400 truncate">{word[lang]}</span>
              </div>
              <span className="shrink-0 text-[10px] text-gray-300">{formatTime(getTimestamp(i))}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Card Carousel Panel */}
      {selectedIndex !== null && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end">
          {/* Full backdrop — blocks all background interaction */}
          <div
            className="absolute inset-0 bg-black/40"
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
                <div className={`rounded-2xl p-5 shadow-lg transition-all ${
                  i === selectedIndex
                    ? "bg-white opacity-100"
                    : "bg-white/90 opacity-60 scale-95"
                }`}>
                  {/* Top row */}
                  <div className="flex items-center justify-between">
                    <span className="text-3xl">{word.emoji}</span>
                    <span className="rounded-full bg-gray-100 px-2.5 py-0.5 text-[10px] font-medium text-gray-500">
                      {word.partOfSpeech}
                    </span>
                  </div>

                  {/* Korean + romanization block */}
                  <div
                    className={`mt-3 inline-flex flex-col rounded-xl px-4 py-2 cursor-pointer transition-all ${
                      isSpeaking && i === selectedIndex
                        ? "bg-gradient-to-r from-amber-50 via-pink-50 to-purple-50 ring-2 ring-pink-300 animate-pulse"
                        : "bg-gray-50 hover:bg-gray-100 active:bg-pink-50"
                    }`}
                    onClick={(e) => { e.stopPropagation(); handleSpeak(word.korean, true); seekToWord(i); }}
                  >
                    <span className="text-3xl font-bold text-gray-900">{word.korean}</span>
                    <span className="text-sm text-pink-500">[ {word.romanization} ]</span>
                  </div>

                  {/* Hangul decomposition */}
                  <div className="mt-2 grid grid-cols-6 gap-1">
                    {decomposeHangul(word.korean).flatMap((s, si) =>
                      s.parts.map((p, pi) => (
                        <button
                          key={`${si}-${pi}`}
                          onClick={(e) => { e.stopPropagation(); handleSpeak(p); }}
                          className={`rounded-lg border border-gray-100 bg-gray-50 px-2.5 py-1.5 text-base font-bold transition-colors hover:bg-gray-100 active:bg-pink-50 ${pi === 0 ? "text-purple-600" : pi === 1 ? "text-green-600" : "text-orange-500"}`}
                        >
                          {p}
                        </button>
                      ))
                    )}
                  </div>

                  <div
                    className="mt-3 inline-block rounded-xl bg-gray-50 px-4 py-2 cursor-pointer hover:bg-gray-100 active:bg-pink-50 transition-colors"
                    onClick={(e) => { e.stopPropagation(); handleSpeak(word[lang], false, LANG_CODES[lang]); }}
                  >
                    <p className="text-lg text-gray-700">{word[lang]}</p>
                  </div>

                  <div className="mt-2 flex items-center justify-between text-xs text-gray-300">
                    <button
                      onClick={(e) => { e.stopPropagation(); seekToWord(i); }}
                      className="flex items-center gap-1 rounded-full bg-gray-50 px-2 py-0.5 text-pink-400 hover:bg-pink-50 transition-colors"
                    >
                      <svg className="h-3 w-3" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                      {formatTime(getTimestamp(i))}
                    </button>
                    <span>{i + 1} / {currentSong.words.length}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
