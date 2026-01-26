"""
Management command to seed the Master Exercise Bank with 154+ exercises.
"""
from django.core.management.base import BaseCommand
from workouts.models import Exercise


class Command(BaseCommand):
    help = 'Seeds the database with 154 exercises across all muscle groups'

    def handle(self, *args, **options):
        exercises = self.get_exercises()

        created_count = 0
        updated_count = 0

        for exercise_data in exercises:
            exercise, created = Exercise.objects.update_or_create(
                name=exercise_data['name'],
                defaults={
                    'description': exercise_data.get('description', ''),
                    'muscle_group': exercise_data['muscle_group'],
                    'is_public': True,
                    'created_by': None,
                }
            )
            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully seeded {created_count} new exercises, '
                f'updated {updated_count} existing exercises. '
                f'Total: {Exercise.objects.filter(is_public=True).count()} public exercises.'
            )
        )

    def get_exercises(self):
        """Returns list of all exercises to seed."""
        exercises = []

        # CHEST (15 exercises)
        chest_exercises = [
            {
                'name': 'Barbell Bench Press',
                'description': 'Lie on a flat bench, grip the barbell slightly wider than shoulder-width, lower to chest, and press up.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Incline Barbell Bench Press',
                'description': 'Perform bench press on an inclined bench (30-45 degrees) to target upper chest.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Decline Barbell Bench Press',
                'description': 'Perform bench press on a declined bench to target lower chest.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Dumbbell Bench Press',
                'description': 'Lie on a flat bench with dumbbells, press up while maintaining control through full range of motion.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Incline Dumbbell Bench Press',
                'description': 'Perform dumbbell press on an inclined bench to emphasize upper chest development.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Decline Dumbbell Bench Press',
                'description': 'Perform dumbbell press on a declined bench to target lower chest fibers.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Dumbbell Flyes',
                'description': 'Lie on bench with arms extended, lower dumbbells in an arc motion, squeeze chest to return.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Incline Dumbbell Flyes',
                'description': 'Perform fly movement on an incline bench to target upper chest.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Cable Crossovers',
                'description': 'Stand between cable machines, bring handles together in front of chest with slight bend in elbows.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Low Cable Crossovers',
                'description': 'Perform cable crossover with pulleys set low to target upper chest.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Machine Chest Press',
                'description': 'Seated chest press on machine for controlled movement and consistent resistance.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Pec Deck Machine',
                'description': 'Seated fly movement on machine, squeeze chest at the end of each rep.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Push-Ups',
                'description': 'Classic bodyweight exercise. Hands shoulder-width apart, lower chest to floor, push up.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Decline Push-Ups',
                'description': 'Feet elevated on bench or step to increase difficulty and target upper chest.',
                'muscle_group': 'chest'
            },
            {
                'name': 'Diamond Push-Ups',
                'description': 'Push-ups with hands together forming a diamond shape to emphasize inner chest and triceps.',
                'muscle_group': 'chest'
            },
        ]
        exercises.extend(chest_exercises)

        # BACK (18 exercises)
        back_exercises = [
            {
                'name': 'Barbell Deadlift',
                'description': 'Hinge at hips, grip bar outside knees, drive through heels to stand. Keep back flat.',
                'muscle_group': 'back'
            },
            {
                'name': 'Conventional Deadlift',
                'description': 'Standard deadlift with feet hip-width apart and hands just outside legs.',
                'muscle_group': 'back'
            },
            {
                'name': 'Sumo Deadlift',
                'description': 'Wide stance deadlift with hands inside legs, more quad and inner thigh emphasis.',
                'muscle_group': 'back'
            },
            {
                'name': 'Romanian Deadlift',
                'description': 'Hip hinge movement with slight knee bend, lower bar along thighs, feel hamstring stretch.',
                'muscle_group': 'back'
            },
            {
                'name': 'Barbell Bent-Over Row',
                'description': 'Hinge forward, pull barbell to lower chest/upper abs, squeeze shoulder blades.',
                'muscle_group': 'back'
            },
            {
                'name': 'Dumbbell Bent-Over Row',
                'description': 'Hinge forward with dumbbells, row to sides of torso, control the negative.',
                'muscle_group': 'back'
            },
            {
                'name': 'T-Bar Row',
                'description': 'Straddle T-bar, row to chest with neutral grip for mid-back thickness.',
                'muscle_group': 'back'
            },
            {
                'name': 'Seated Cable Row',
                'description': 'Sit at cable station, pull handle to midsection, squeeze shoulder blades together.',
                'muscle_group': 'back'
            },
            {
                'name': 'Single-Arm Dumbbell Row',
                'description': 'One knee on bench, row dumbbell to hip, keep core tight and back flat.',
                'muscle_group': 'back'
            },
            {
                'name': 'Lat Pulldown (Wide Grip)',
                'description': 'Wide overhand grip, pull bar to upper chest, control the return.',
                'muscle_group': 'back'
            },
            {
                'name': 'Lat Pulldown (Close Grip)',
                'description': 'Close grip pulldown for more bicep involvement and lower lat emphasis.',
                'muscle_group': 'back'
            },
            {
                'name': 'Pull-Ups',
                'description': 'Grip bar overhand shoulder-width, pull chest to bar, control descent.',
                'muscle_group': 'back'
            },
            {
                'name': 'Chin-Ups',
                'description': 'Underhand grip pull-up with more bicep emphasis.',
                'muscle_group': 'back'
            },
            {
                'name': 'Assisted Pull-Ups',
                'description': 'Machine-assisted pull-ups for building strength toward unassisted reps.',
                'muscle_group': 'back'
            },
            {
                'name': 'Straight-Arm Pulldown',
                'description': 'Standing lat pulldown with straight arms to isolate lats.',
                'muscle_group': 'back'
            },
            {
                'name': 'Machine Row',
                'description': 'Seated row on machine for controlled, consistent resistance.',
                'muscle_group': 'back'
            },
            {
                'name': 'Hyperextensions',
                'description': 'Lower back extension on hyperextension bench, squeeze glutes at top.',
                'muscle_group': 'back'
            },
            {
                'name': 'Good Mornings',
                'description': 'Barbell on shoulders, hinge forward keeping back flat, return to standing.',
                'muscle_group': 'back'
            },
        ]
        exercises.extend(back_exercises)

        # SHOULDERS (15 exercises)
        shoulder_exercises = [
            {
                'name': 'Barbell Overhead Press',
                'description': 'Standing press, drive bar from shoulders to overhead, keep core tight.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Seated Dumbbell Shoulder Press',
                'description': 'Seated with back support, press dumbbells from shoulders to overhead.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Arnold Press',
                'description': 'Rotating dumbbell press that starts palms facing you and rotates to forward.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Dumbbell Lateral Raises',
                'description': 'Raise dumbbells to sides until parallel with floor, slight bend in elbows.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Cable Lateral Raises',
                'description': 'Lateral raise using cable for constant tension throughout movement.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Front Dumbbell Raises',
                'description': 'Raise dumbbells in front of body to shoulder height, target front delts.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Barbell Front Raise',
                'description': 'Raise barbell in front of body to shoulder height with overhand grip.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Rear Delt Flyes (Bent-Over)',
                'description': 'Hinge forward, raise dumbbells to sides targeting rear deltoids.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Reverse Pec Deck',
                'description': 'Face the pec deck machine, perform reverse fly motion for rear delts.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Face Pulls',
                'description': 'Pull rope attachment to face level, externally rotate at end position.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Upright Rows',
                'description': 'Pull barbell or dumbbells up along body to chin level, elbows high.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Barbell Shrugs',
                'description': 'Shrug shoulders straight up with barbell, squeeze traps at top.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Dumbbell Shrugs',
                'description': 'Shrug shoulders with dumbbells at sides for trap development.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Machine Shoulder Press',
                'description': 'Seated shoulder press on machine for controlled pressing movement.',
                'muscle_group': 'shoulders'
            },
            {
                'name': 'Landmine Press',
                'description': 'Press barbell anchored in landmine attachment at an angle for shoulder health.',
                'muscle_group': 'shoulders'
            },
        ]
        exercises.extend(shoulder_exercises)

        # ARMS - BICEPS (12 exercises)
        biceps_exercises = [
            {
                'name': 'Barbell Bicep Curl',
                'description': 'Standing curl with barbell, keep elbows at sides, squeeze at top.',
                'muscle_group': 'arms'
            },
            {
                'name': 'EZ-Bar Curl',
                'description': 'Curl with EZ-bar for comfortable wrist position.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Dumbbell Bicep Curl',
                'description': 'Alternating or simultaneous dumbbell curls for bicep development.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Hammer Curls',
                'description': 'Neutral grip dumbbell curls targeting brachialis and brachioradialis.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Incline Dumbbell Curl',
                'description': 'Curl from inclined position for greater stretch on biceps.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Preacher Curl (Barbell)',
                'description': 'Curl on preacher bench with barbell for strict bicep isolation.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Preacher Curl (Dumbbell)',
                'description': 'Single-arm preacher curl with dumbbell for unilateral work.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Concentration Curl',
                'description': 'Seated curl with elbow braced against inner thigh for peak contraction.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Cable Bicep Curl',
                'description': 'Standing curl at cable machine for constant tension.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Spider Curls',
                'description': 'Curl over incline bench facing down for strict bicep isolation.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Reverse Curl',
                'description': 'Curl with overhand grip to target brachioradialis and forearms.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Zottman Curls',
                'description': 'Curl up with supinated grip, rotate to pronated grip for lowering.',
                'muscle_group': 'arms'
            },
        ]
        exercises.extend(biceps_exercises)

        # ARMS - TRICEPS (12 exercises)
        triceps_exercises = [
            {
                'name': 'Close-Grip Bench Press',
                'description': 'Bench press with narrow grip to emphasize triceps.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Skull Crushers (EZ-Bar)',
                'description': 'Lying tricep extension lowering bar to forehead, extend arms.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Overhead Tricep Extension (Dumbbell)',
                'description': 'Single dumbbell overhead extension for long head tricep.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Overhead Tricep Extension (Cable)',
                'description': 'Cable overhead extension with rope attachment.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Pushdown (Rope)',
                'description': 'Cable pushdown with rope, spread at bottom for full contraction.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Pushdown (V-Bar)',
                'description': 'Cable pushdown with V-bar attachment for heavier loads.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Pushdown (Straight Bar)',
                'description': 'Cable pushdown with straight bar for overhand grip variation.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Dips',
                'description': 'Parallel bar dips with upright torso to target triceps.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Bench Dips',
                'description': 'Dips using bench behind you, feet extended in front.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Diamond Push-Ups',
                'description': 'Push-ups with hands in diamond position for tricep emphasis.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Tricep Kickbacks',
                'description': 'Bent over dumbbell kickback, extend arm behind you.',
                'muscle_group': 'arms'
            },
            {
                'name': 'Cable Overhead Tricep Extension',
                'description': 'Facing away from cable, extend arms overhead for long head.',
                'muscle_group': 'arms'
            },
        ]
        exercises.extend(triceps_exercises)

        # LEGS - QUADS (12 exercises)
        quad_exercises = [
            {
                'name': 'Barbell Back Squat',
                'description': 'Bar on upper back, squat to parallel or below, drive through heels.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Barbell Front Squat',
                'description': 'Bar on front shoulders, elbows high, squat with upright torso.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Goblet Squat',
                'description': 'Hold dumbbell at chest, squat with upright torso.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Leg Press',
                'description': 'Machine leg press for heavy quad loading with back support.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Hack Squat',
                'description': 'Machine squat with back against pad for quad isolation.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Bulgarian Split Squat',
                'description': 'Rear foot elevated, lunge down on front leg for unilateral work.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Walking Lunges',
                'description': 'Alternating forward lunges traveling across the floor.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Stationary Lunges',
                'description': 'Forward lunge returning to start position each rep.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Reverse Lunges',
                'description': 'Step backward into lunge, easier on knees than forward lunges.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Leg Extension Machine',
                'description': 'Seated quad extension for isolation work.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Sissy Squats',
                'description': 'Lean back while squatting for extreme quad stretch.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Step-Ups',
                'description': 'Step onto elevated platform, drive through heel.',
                'muscle_group': 'legs'
            },
        ]
        exercises.extend(quad_exercises)

        # LEGS - HAMSTRINGS (10 exercises)
        hamstring_exercises = [
            {
                'name': 'Stiff-Leg Deadlift',
                'description': 'Deadlift variation with minimal knee bend for hamstring focus.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Lying Leg Curl',
                'description': 'Face-down leg curl machine for hamstring isolation.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Seated Leg Curl',
                'description': 'Seated leg curl machine variation.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Standing Leg Curl',
                'description': 'Single-leg standing curl at machine.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Nordic Hamstring Curl',
                'description': 'Advanced bodyweight eccentric hamstring exercise.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Glute-Ham Raise',
                'description': 'GHD exercise for posterior chain development.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Single-Leg Romanian Deadlift',
                'description': 'Unilateral RDL for balance and hamstring development.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Kettlebell Swing',
                'description': 'Hip hinge swing movement for posterior chain power.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Cable Pull-Through',
                'description': 'Cable hip hinge for glute and hamstring activation.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Leg Press (Feet High)',
                'description': 'Leg press with feet placed high for hamstring emphasis.',
                'muscle_group': 'legs'
            },
        ]
        exercises.extend(hamstring_exercises)

        # LEGS - CALVES (6 exercises)
        calf_exercises = [
            {
                'name': 'Standing Calf Raise (Machine)',
                'description': 'Standing calf raise on machine for gastrocnemius.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Seated Calf Raise',
                'description': 'Seated raise for soleus muscle development.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Donkey Calf Raise',
                'description': 'Bent over calf raise with weight on lower back.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Single-Leg Calf Raise',
                'description': 'Unilateral calf raise for balance and strength.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Calf Raise on Leg Press',
                'description': 'Calf raise using leg press machine platform.',
                'muscle_group': 'legs'
            },
            {
                'name': 'Jump Rope (Calf Focus)',
                'description': 'Jump rope staying on balls of feet for calf endurance.',
                'muscle_group': 'legs'
            },
        ]
        exercises.extend(calf_exercises)

        # GLUTES (12 exercises)
        glute_exercises = [
            {
                'name': 'Hip Thrust (Barbell)',
                'description': 'Back against bench, drive hips up with barbell on lap.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Hip Thrust (Dumbbell)',
                'description': 'Hip thrust variation using single dumbbell for lighter loads.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Glute Bridge',
                'description': 'Floor-based hip thrust movement for glute activation.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Single-Leg Glute Bridge',
                'description': 'Unilateral glute bridge for strength imbalance correction.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Cable Kickbacks',
                'description': 'Standing cable kickback for glute isolation.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Cable Pull-Throughs',
                'description': 'Hip hinge with cable for glute and hamstring work.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Sumo Squat',
                'description': 'Wide stance squat with toes pointed out for glute/adductor emphasis.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Step-Ups (Glute Focus)',
                'description': 'Higher box step-ups with forward lean for glute emphasis.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Lateral Band Walks',
                'description': 'Side steps with resistance band for glute medius activation.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Clamshells',
                'description': 'Side-lying hip abduction with band for glute medius.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Frog Pumps',
                'description': 'Glute bridge with feet together, knees out.',
                'muscle_group': 'glutes'
            },
            {
                'name': 'Romanian Deadlift (Glute Focus)',
                'description': 'RDL with emphasis on squeezing glutes at top position.',
                'muscle_group': 'glutes'
            },
        ]
        exercises.extend(glute_exercises)

        # CORE (15 exercises)
        core_exercises = [
            {
                'name': 'Plank',
                'description': 'Hold push-up position on forearms, maintain flat back.',
                'muscle_group': 'core'
            },
            {
                'name': 'Side Plank',
                'description': 'Lateral plank on one forearm for oblique emphasis.',
                'muscle_group': 'core'
            },
            {
                'name': 'Dead Bug',
                'description': 'Lying on back, extend opposite arm and leg while maintaining back flat.',
                'muscle_group': 'core'
            },
            {
                'name': 'Bird Dog',
                'description': 'On all fours, extend opposite arm and leg for stability.',
                'muscle_group': 'core'
            },
            {
                'name': 'Hollow Body Hold',
                'description': 'Lying on back, lift shoulders and legs, hold position.',
                'muscle_group': 'core'
            },
            {
                'name': 'Bicycle Crunches',
                'description': 'Alternating elbow to opposite knee in cycling motion.',
                'muscle_group': 'core'
            },
            {
                'name': 'Russian Twists',
                'description': 'Seated rotation with weight for oblique strength.',
                'muscle_group': 'core'
            },
            {
                'name': 'Cable Woodchops',
                'description': 'Diagonal cable rotation for functional core strength.',
                'muscle_group': 'core'
            },
            {
                'name': 'Hanging Leg Raises',
                'description': 'Hang from bar, raise legs to parallel or higher.',
                'muscle_group': 'core'
            },
            {
                'name': 'Lying Leg Raises',
                'description': 'Lying on back, raise legs while keeping lower back pressed down.',
                'muscle_group': 'core'
            },
            {
                'name': 'Ab Wheel Rollout',
                'description': 'Roll ab wheel forward, control return using core strength.',
                'muscle_group': 'core'
            },
            {
                'name': 'Pallof Press',
                'description': 'Cable anti-rotation press for core stability.',
                'muscle_group': 'core'
            },
            {
                'name': 'Dragon Flags',
                'description': 'Advanced movement lowering body from shoulders like a flag.',
                'muscle_group': 'core'
            },
            {
                'name': 'V-Ups',
                'description': 'Simultaneously raise torso and legs to form V shape.',
                'muscle_group': 'core'
            },
            {
                'name': 'Mountain Climbers',
                'description': 'Plank position, alternate driving knees toward chest.',
                'muscle_group': 'core'
            },
        ]
        exercises.extend(core_exercises)

        # CARDIO (12 exercises)
        cardio_exercises = [
            {
                'name': 'Treadmill Running',
                'description': 'Running on treadmill at various speeds and inclines.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Treadmill Walking (Incline)',
                'description': 'Walking at steep incline for low-impact cardio.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Stationary Bike',
                'description': 'Cycling on stationary bike for cardiovascular conditioning.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Rowing Machine',
                'description': 'Full-body cardio using rowing ergometer.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Stair Climber',
                'description': 'Continuous stair climbing for leg endurance and cardio.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Elliptical',
                'description': 'Low-impact cardio machine with arm and leg movement.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Jump Rope',
                'description': 'Skipping rope for cardio, coordination, and calf work.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Burpees',
                'description': 'Full-body cardio exercise combining squat, plank, and jump.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Box Jumps',
                'description': 'Explosive jump onto elevated platform for power and cardio.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Battle Ropes',
                'description': 'Alternating or simultaneous rope waves for upper body cardio.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Assault Bike',
                'description': 'Air resistance bike with arm handles for full-body cardio.',
                'muscle_group': 'cardio'
            },
            {
                'name': 'Swimming',
                'description': 'Full-body low-impact cardio in pool.',
                'muscle_group': 'cardio'
            },
        ]
        exercises.extend(cardio_exercises)

        # FULL BODY (15 exercises)
        full_body_exercises = [
            {
                'name': 'Barbell Clean',
                'description': 'Explosive pull from floor to front rack position.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Power Clean',
                'description': 'Clean caught in quarter squat for power development.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Clean and Jerk',
                'description': 'Olympic lift combining clean and overhead jerk.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Snatch',
                'description': 'Olympic lift pulling bar from floor to overhead in one motion.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Thrusters',
                'description': 'Front squat combined with overhead press in one fluid motion.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Man Makers',
                'description': 'Dumbbell complex: burpee, row, clean, press.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Turkish Get-Up',
                'description': 'Ground to standing while holding weight overhead.',
                'muscle_group': 'full_body'
            },
            {
                'name': "Farmer's Walk",
                'description': 'Walk while carrying heavy weights at sides.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Sled Push',
                'description': 'Push weighted sled for conditioning and leg drive.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Sled Pull',
                'description': 'Pull weighted sled using rope or harness.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Tire Flips',
                'description': 'Flip large tire end over end for strength and conditioning.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Wall Balls',
                'description': 'Squat and throw medicine ball to target on wall.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Kettlebell Swings',
                'description': 'Hip hinge swing with kettlebell for posterior chain power.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Medicine Ball Slams',
                'description': 'Explosive overhead throw of medicine ball to ground.',
                'muscle_group': 'full_body'
            },
            {
                'name': 'Bear Crawl',
                'description': 'Crawling on hands and feet for full-body conditioning.',
                'muscle_group': 'full_body'
            },
        ]
        exercises.extend(full_body_exercises)

        return exercises
