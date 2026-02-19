"use client";

import { motion } from "framer-motion";
import { Dumbbell, Heart, Activity, Flame, Trophy, Zap } from "lucide-react";

const floatingIcons = [
  { Icon: Dumbbell, top: "10%", left: "15%", size: 48, delay: 0 },
  { Icon: Heart, top: "25%", right: "20%", size: 36, delay: 0.5 },
  { Icon: Activity, top: "60%", left: "10%", size: 40, delay: 1.0 },
  { Icon: Flame, top: "45%", right: "12%", size: 56, delay: 1.5 },
  { Icon: Trophy, top: "75%", left: "25%", size: 32, delay: 2.0 },
  { Icon: Zap, top: "15%", left: "60%", size: 44, delay: 0.8 },
];

const taglineWords = ["Train", "Smarter.", "Grow", "Faster."];

const featurePills = ["AI-Powered", "White-Label Ready", "500+ Trainers"];

export function LoginHero() {
  return (
    <div
      className="relative hidden h-full overflow-hidden lg:flex lg:items-center lg:justify-center"
      aria-hidden="true"
    >
      {/* Animated gradient background */}
      <div className="absolute inset-0 animate-gradient-shift bg-gradient-to-br from-indigo-600 via-blue-600 to-purple-700 dark:from-slate-900 dark:via-indigo-950 dark:to-slate-900" />

      {/* Dot grid overlay */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage:
            "radial-gradient(circle, rgba(255,255,255,0.03) 1px, transparent 1px)",
          backgroundSize: "24px 24px",
        }}
      />

      {/* Floating icons */}
      {floatingIcons.map(({ Icon, size, delay, ...pos }, i) => (
        <div
          key={i}
          className="absolute animate-float text-white/10 dark:text-white/5"
          style={{
            ...pos,
            animationDelay: `${delay}s`,
            animationDuration: `${3 + (i % 4)}s`,
          }}
        >
          <Icon style={{ width: size, height: size }} />
        </div>
      ))}

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center gap-8 px-12 text-center">
        <div className="flex flex-wrap justify-center gap-x-4 gap-y-2">
          {taglineWords.map((word, i) => (
            <motion.span
              key={word}
              className="text-4xl font-bold tracking-tight text-white xl:text-5xl"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2 + i * 0.1 }}
            >
              {word}
            </motion.span>
          ))}
        </div>

        <motion.p
          className="max-w-md text-lg text-white/70"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.8 }}
        >
          The all-in-one platform for personal trainers to manage clients,
          programs, and grow their business.
        </motion.p>

        <div className="flex gap-3">
          {featurePills.map((pill, i) => (
            <motion.span
              key={pill}
              className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-sm font-medium text-white/80 backdrop-blur-sm"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 1.0 + i * 0.15 }}
            >
              {pill}
            </motion.span>
          ))}
        </div>
      </div>
    </div>
  );
}
