"use client";

import { useState } from "react";
import { VideoOff } from "lucide-react";

interface ExerciseVideoPlayerProps {
  videoUrl: string;
}

function extractYouTubeId(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/|youtube-nocookie\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
  );
  return match ? match[1] : null;
}

export function ExerciseVideoPlayer({ videoUrl }: ExerciseVideoPlayerProps) {
  const [error, setError] = useState(false);

  if (error) {
    return (
      <div
        className="flex h-48 w-full items-center justify-center rounded-lg bg-muted"
        role="alert"
      >
        <div className="flex flex-col items-center gap-2 text-muted-foreground">
          <VideoOff className="h-8 w-8" aria-hidden="true" />
          <p className="text-sm">Video unavailable</p>
        </div>
      </div>
    );
  }

  const ytId = extractYouTubeId(videoUrl);

  if (ytId) {
    return (
      <div className="overflow-hidden rounded-lg bg-black">
        <div className="relative w-full" style={{ paddingBottom: "56.25%" }}>
          <iframe
            src={`https://www.youtube-nocookie.com/embed/${ytId}`}
            title="Exercise demonstration video"
            allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
            loading="lazy"
            className="absolute inset-0 h-full w-full"
            aria-label="Exercise demonstration video"
          />
        </div>
      </div>
    );
  }

  // Direct video URL or unknown format — try as native <video>
  return (
    <div className="overflow-hidden rounded-lg bg-black">
      <video
        src={videoUrl}
        controls
        loop
        muted
        playsInline
        preload="metadata"
        className="w-full"
        onError={() => setError(true)}
        aria-label="Exercise demonstration video"
      >
        Your browser does not support the video element.
      </video>
    </div>
  );
}
