"use client";

import { useState } from "react";
import { VideoOff } from "lucide-react";

interface ExerciseVideoPlayerProps {
  videoUrl: string;
}

function extractYouTubeId(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/,
  );
  return match ? match[1] : null;
}

function isDirectVideoUrl(url: string): boolean {
  return /\.(mp4|webm|ogg|mov|m4v)(\?.*)?$/i.test(url);
}

export function ExerciseVideoPlayer({ videoUrl }: ExerciseVideoPlayerProps) {
  const [error, setError] = useState(false);

  if (error) {
    return (
      <div className="flex h-48 w-full items-center justify-center rounded-lg bg-muted">
        <div className="flex flex-col items-center gap-2 text-muted-foreground">
          <VideoOff className="h-8 w-8" />
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
            title="Exercise video"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
            className="absolute inset-0 h-full w-full"
            onError={() => setError(true)}
          />
        </div>
      </div>
    );
  }

  if (isDirectVideoUrl(videoUrl)) {
    return (
      <div className="overflow-hidden rounded-lg bg-black">
        <video
          src={videoUrl}
          controls
          loop
          muted
          playsInline
          className="w-full"
          onError={() => setError(true)}
        >
          Your browser does not support the video element.
        </video>
      </div>
    );
  }

  // Unknown URL format — try as direct video, fall back on error
  return (
    <div className="overflow-hidden rounded-lg bg-black">
      <video
        src={videoUrl}
        controls
        loop
        muted
        playsInline
        className="w-full"
        onError={() => setError(true)}
      >
        Your browser does not support the video element.
      </video>
    </div>
  );
}
