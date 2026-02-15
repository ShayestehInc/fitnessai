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
