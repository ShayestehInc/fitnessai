# Pipeline 31 Focus: Smart Program Generator

## Priority
Auto-generate complete workout programs based on split type, difficulty, goal, and duration. Full-stack feature across backend, web, and mobile.

## Key Changes
- Backend: Exercise model gains `difficulty_level` + `category`, AI classification command, program generation service, new API endpoint at `POST /api/trainer/program-templates/generate/`
- Web: 4-step generator wizard at `/programs/generate`, enhanced exercise picker with difficulty filter
- Mobile: 3-step generator wizard, enhanced exercise picker with difficulty filter

## Scope
- Exercise difficulty classification (beginner/intermediate/advanced)
- Program generation service with split configs, exercise selection, sets/reps schemes, progressive overload, nutrition templates
- Generator wizard UIs on web and mobile
- Integration with existing program builder (generated data loads into builder for customization)
