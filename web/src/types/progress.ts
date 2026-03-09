export interface WeightEntry {
  date: string;
  weight_kg: number;
}

export interface VolumeEntry {
  date: string;
  volume: number;
}

export interface AdherenceEntry {
  date: string;
  logged_food: boolean;
  logged_workout: boolean;
  hit_protein: boolean;
}

export interface TraineeProgress {
  weight_progress: WeightEntry[];
  volume_progress: VolumeEntry[];
  adherence_progress: AdherenceEntry[];
}

export interface ProgressPhoto {
  id: number;
  trainee: number;
  trainee_email: string;
  photo: string;
  photo_url: string | null;
  category: "front" | "side" | "back" | "other";
  date: string;
  measurements: Record<string, number>;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface ProgressPhotoPage {
  count: number;
  next: string | null;
  previous: string | null;
  results: ProgressPhoto[];
}

export type PhotoCategory = "all" | "front" | "side" | "back" | "other";
