# Focus: Trainer Packet v6.5 — Step 6: Modality Library with Counting and Guardrails

## Priority

Critical — Step 6 of the v6.5 build order. Foundation for progression engine and session runner.

## What to Build

### 1. SetStructureModality Model

- 15 supported modalities: Straight Sets, Down Sets, Controlled Eccentrics, Giant Sets, Myo-reps, Drop Sets, Supersets (Agonist-Antagonist, Pre-Exhaust, Compound), Occlusion, Circuit, Cluster Sets, Rest-Pause, Static Sets, Tri-sets, Pyramid, Athletic Guardrail
- Each modality has: counting rules (volume multiplier), guardrails (what it can/can't be applied to), fatigue modifier

### 2. Counting Rules

- Volume multipliers per modality (e.g., 1.0x straight sets, 0.67x drop sets/myo-reps/occlusion, 2.0x pre-exhaust supersets)
- Integration with workload engine for accurate volume tracking

### 3. Guardrails

- Athletic movements can't use drop sets/myo-reps
- Heavy compounds can't use drop sets
- Volume-unstable users can't use giant sets
- Weekly hard-set ceiling 8-20 per muscle group

### 4. PlanSlot Integration

- Add set_structure_modality FK to PlanSlot
- Add modality_details JSON for modality-specific parameters
- Add modality_volume_contribution Decimal

### 5. Generator Integration

- Enhance A5 (SET_SET_STRUCTURE) to assign modalities based on goal/role/slot

## What NOT to Build

- Progression engine integration (Step 7)
- Session runner (Step 8)
- AI-powered modality selection
