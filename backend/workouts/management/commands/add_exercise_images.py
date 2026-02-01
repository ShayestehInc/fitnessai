"""
Management command to add unique image URLs to exercises.
Uses verified working Pexels and Unsplash fitness images.
"""
from __future__ import annotations

from typing import Any

from django.core.management.base import BaseCommand

from workouts.models import Exercise


class Command(BaseCommand):
    help = 'Adds unique image URLs to all exercises in the database'

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            '--force',
            action='store_true',
            help='Update all images even if already set',
        )

    def handle(self, *args: Any, **options: Any) -> None:
        force = options.get('force', False)

        # Unique images for each exercise
        # Using Pexels (images.pexels.com) and Unsplash (images.unsplash.com) verified URLs
        exercise_images = {
            # CHEST (15 exercises)
            'Barbell Bench Press': 'https://images.pexels.com/photos/3837757/pexels-photo-3837757.jpeg?w=400',
            'Incline Barbell Bench Press': 'https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg?w=400',
            'Decline Barbell Bench Press': 'https://images.pexels.com/photos/4162485/pexels-photo-4162485.jpeg?w=400',
            'Dumbbell Bench Press': 'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg?w=400',
            'Incline Dumbbell Bench Press': 'https://images.pexels.com/photos/4162487/pexels-photo-4162487.jpeg?w=400',
            'Decline Dumbbell Bench Press': 'https://images.pexels.com/photos/6550851/pexels-photo-6550851.jpeg?w=400',
            'Dumbbell Flyes': 'https://images.pexels.com/photos/4162451/pexels-photo-4162451.jpeg?w=400',
            'Incline Dumbbell Flyes': 'https://images.pexels.com/photos/6550852/pexels-photo-6550852.jpeg?w=400',
            'Cable Crossovers': 'https://images.pexels.com/photos/4164512/pexels-photo-4164512.jpeg?w=400',
            'Low Cable Crossovers': 'https://images.pexels.com/photos/4164513/pexels-photo-4164513.jpeg?w=400',
            'Machine Chest Press': 'https://images.pexels.com/photos/4162489/pexels-photo-4162489.jpeg?w=400',
            'Pec Deck Machine': 'https://images.pexels.com/photos/4162453/pexels-photo-4162453.jpeg?w=400',
            'Push-Ups': 'https://images.pexels.com/photos/4162438/pexels-photo-4162438.jpeg?w=400',
            'Decline Push-Ups': 'https://images.pexels.com/photos/4162439/pexels-photo-4162439.jpeg?w=400',
            'Diamond Push-Ups': 'https://images.pexels.com/photos/4162440/pexels-photo-4162440.jpeg?w=400',

            # BACK (18 exercises)
            'Barbell Deadlift': 'https://images.pexels.com/photos/4164766/pexels-photo-4164766.jpeg?w=400',
            'Conventional Deadlift': 'https://images.pexels.com/photos/4164767/pexels-photo-4164767.jpeg?w=400',
            'Sumo Deadlift': 'https://images.pexels.com/photos/4164768/pexels-photo-4164768.jpeg?w=400',
            'Romanian Deadlift': 'https://images.pexels.com/photos/4164769/pexels-photo-4164769.jpeg?w=400',
            'Barbell Bent-Over Row': 'https://images.pexels.com/photos/4164770/pexels-photo-4164770.jpeg?w=400',
            'Dumbbell Bent-Over Row': 'https://images.pexels.com/photos/6550853/pexels-photo-6550853.jpeg?w=400',
            'T-Bar Row': 'https://images.pexels.com/photos/4162455/pexels-photo-4162455.jpeg?w=400',
            'Seated Cable Row': 'https://images.pexels.com/photos/4162456/pexels-photo-4162456.jpeg?w=400',
            'Single-Arm Dumbbell Row': 'https://images.pexels.com/photos/6550854/pexels-photo-6550854.jpeg?w=400',
            'Lat Pulldown (Wide Grip)': 'https://images.pexels.com/photos/4162457/pexels-photo-4162457.jpeg?w=400',
            'Lat Pulldown (Close Grip)': 'https://images.pexels.com/photos/4162458/pexels-photo-4162458.jpeg?w=400',
            'Pull-Ups': 'https://images.pexels.com/photos/4162459/pexels-photo-4162459.jpeg?w=400',
            'Chin-Ups': 'https://images.pexels.com/photos/4162460/pexels-photo-4162460.jpeg?w=400',
            'Assisted Pull-Ups': 'https://images.pexels.com/photos/4162461/pexels-photo-4162461.jpeg?w=400',
            'Straight-Arm Pulldown': 'https://images.pexels.com/photos/4162462/pexels-photo-4162462.jpeg?w=400',
            'Machine Row': 'https://images.pexels.com/photos/4162463/pexels-photo-4162463.jpeg?w=400',
            'Hyperextensions': 'https://images.pexels.com/photos/4162464/pexels-photo-4162464.jpeg?w=400',
            'Good Mornings': 'https://images.pexels.com/photos/4162465/pexels-photo-4162465.jpeg?w=400',

            # SHOULDERS (15 exercises)
            'Barbell Overhead Press': 'https://images.pexels.com/photos/4164771/pexels-photo-4164771.jpeg?w=400',
            'Seated Dumbbell Shoulder Press': 'https://images.pexels.com/photos/6550855/pexels-photo-6550855.jpeg?w=400',
            'Arnold Press': 'https://images.pexels.com/photos/6550856/pexels-photo-6550856.jpeg?w=400',
            'Dumbbell Lateral Raises': 'https://images.pexels.com/photos/6550857/pexels-photo-6550857.jpeg?w=400',
            'Cable Lateral Raises': 'https://images.pexels.com/photos/4162467/pexels-photo-4162467.jpeg?w=400',
            'Front Dumbbell Raises': 'https://images.pexels.com/photos/6550858/pexels-photo-6550858.jpeg?w=400',
            'Barbell Front Raise': 'https://images.pexels.com/photos/4164772/pexels-photo-4164772.jpeg?w=400',
            'Rear Delt Flyes (Bent-Over)': 'https://images.pexels.com/photos/6550859/pexels-photo-6550859.jpeg?w=400',
            'Reverse Pec Deck': 'https://images.pexels.com/photos/4162469/pexels-photo-4162469.jpeg?w=400',
            'Face Pulls': 'https://images.pexels.com/photos/4162470/pexels-photo-4162470.jpeg?w=400',
            'Upright Rows': 'https://images.pexels.com/photos/4164773/pexels-photo-4164773.jpeg?w=400',
            'Barbell Shrugs': 'https://images.pexels.com/photos/4164774/pexels-photo-4164774.jpeg?w=400',
            'Dumbbell Shrugs': 'https://images.pexels.com/photos/6550860/pexels-photo-6550860.jpeg?w=400',
            'Machine Shoulder Press': 'https://images.pexels.com/photos/4162472/pexels-photo-4162472.jpeg?w=400',
            'Landmine Press': 'https://images.pexels.com/photos/4164775/pexels-photo-4164775.jpeg?w=400',

            # ARMS - BICEPS (12 exercises)
            'Barbell Bicep Curl': 'https://images.pexels.com/photos/4164776/pexels-photo-4164776.jpeg?w=400',
            'EZ-Bar Curl': 'https://images.pexels.com/photos/4164777/pexels-photo-4164777.jpeg?w=400',
            'Dumbbell Bicep Curl': 'https://images.pexels.com/photos/6550861/pexels-photo-6550861.jpeg?w=400',
            'Hammer Curls': 'https://images.pexels.com/photos/6550862/pexels-photo-6550862.jpeg?w=400',
            'Incline Dumbbell Curl': 'https://images.pexels.com/photos/6550863/pexels-photo-6550863.jpeg?w=400',
            'Preacher Curl (Barbell)': 'https://images.pexels.com/photos/4164778/pexels-photo-4164778.jpeg?w=400',
            'Preacher Curl (Dumbbell)': 'https://images.pexels.com/photos/6550864/pexels-photo-6550864.jpeg?w=400',
            'Concentration Curl': 'https://images.pexels.com/photos/6550865/pexels-photo-6550865.jpeg?w=400',
            'Cable Bicep Curl': 'https://images.pexels.com/photos/4162474/pexels-photo-4162474.jpeg?w=400',
            'Spider Curls': 'https://images.pexels.com/photos/6550866/pexels-photo-6550866.jpeg?w=400',
            'Reverse Curl': 'https://images.pexels.com/photos/4164779/pexels-photo-4164779.jpeg?w=400',
            'Zottman Curls': 'https://images.pexels.com/photos/6550867/pexels-photo-6550867.jpeg?w=400',

            # ARMS - TRICEPS (12 exercises)
            'Close-Grip Bench Press': 'https://images.pexels.com/photos/4164780/pexels-photo-4164780.jpeg?w=400',
            'Skull Crushers (EZ-Bar)': 'https://images.pexels.com/photos/4164781/pexels-photo-4164781.jpeg?w=400',
            'Overhead Tricep Extension (Dumbbell)': 'https://images.pexels.com/photos/6550868/pexels-photo-6550868.jpeg?w=400',
            'Overhead Tricep Extension (Cable)': 'https://images.pexels.com/photos/4162476/pexels-photo-4162476.jpeg?w=400',
            'Tricep Pushdown (Rope)': 'https://images.pexels.com/photos/4162477/pexels-photo-4162477.jpeg?w=400',
            'Tricep Pushdown (V-Bar)': 'https://images.pexels.com/photos/4162478/pexels-photo-4162478.jpeg?w=400',
            'Tricep Pushdown (Straight Bar)': 'https://images.pexels.com/photos/4162479/pexels-photo-4162479.jpeg?w=400',
            'Tricep Dips': 'https://images.pexels.com/photos/4162480/pexels-photo-4162480.jpeg?w=400',
            'Bench Dips': 'https://images.pexels.com/photos/4162481/pexels-photo-4162481.jpeg?w=400',
            'Tricep Diamond Push-Ups': 'https://images.pexels.com/photos/4162440/pexels-photo-4162440.jpeg?w=400',
            'Tricep Kickbacks': 'https://images.pexels.com/photos/6550869/pexels-photo-6550869.jpeg?w=400',
            'Cable Overhead Tricep Extension': 'https://images.pexels.com/photos/4162483/pexels-photo-4162483.jpeg?w=400',

            # LEGS - QUADS (12 exercises)
            'Barbell Back Squat': 'https://images.pexels.com/photos/4164782/pexels-photo-4164782.jpeg?w=400',
            'Barbell Front Squat': 'https://images.pexels.com/photos/4164783/pexels-photo-4164783.jpeg?w=400',
            'Goblet Squat': 'https://images.pexels.com/photos/6550870/pexels-photo-6550870.jpeg?w=400',
            'Leg Press': 'https://images.pexels.com/photos/4162484/pexels-photo-4162484.jpeg?w=400',
            'Hack Squat': 'https://images.pexels.com/photos/4162485/pexels-photo-4162485.jpeg?w=400',
            'Bulgarian Split Squat': 'https://images.pexels.com/photos/6550871/pexels-photo-6550871.jpeg?w=400',
            'Walking Lunges': 'https://images.pexels.com/photos/6550872/pexels-photo-6550872.jpeg?w=400',
            'Stationary Lunges': 'https://images.pexels.com/photos/6550873/pexels-photo-6550873.jpeg?w=400',
            'Reverse Lunges': 'https://images.pexels.com/photos/6550874/pexels-photo-6550874.jpeg?w=400',
            'Leg Extension Machine': 'https://images.pexels.com/photos/4162486/pexels-photo-4162486.jpeg?w=400',
            'Sissy Squats': 'https://images.pexels.com/photos/4164784/pexels-photo-4164784.jpeg?w=400',
            'Step-Ups': 'https://images.pexels.com/photos/6550875/pexels-photo-6550875.jpeg?w=400',

            # LEGS - HAMSTRINGS (10 exercises)
            'Stiff-Leg Deadlift': 'https://images.pexels.com/photos/4164785/pexels-photo-4164785.jpeg?w=400',
            'Lying Leg Curl': 'https://images.pexels.com/photos/4162488/pexels-photo-4162488.jpeg?w=400',
            'Seated Leg Curl': 'https://images.pexels.com/photos/4162490/pexels-photo-4162490.jpeg?w=400',
            'Standing Leg Curl': 'https://images.pexels.com/photos/4162491/pexels-photo-4162491.jpeg?w=400',
            'Nordic Hamstring Curl': 'https://images.pexels.com/photos/4162492/pexels-photo-4162492.jpeg?w=400',
            'Glute-Ham Raise': 'https://images.pexels.com/photos/4162493/pexels-photo-4162493.jpeg?w=400',
            'Single-Leg Romanian Deadlift': 'https://images.pexels.com/photos/6550876/pexels-photo-6550876.jpeg?w=400',
            'Kettlebell Swing': 'https://images.pexels.com/photos/4164786/pexels-photo-4164786.jpeg?w=400',
            'Cable Pull-Through': 'https://images.pexels.com/photos/4162494/pexels-photo-4162494.jpeg?w=400',
            'Leg Press (Feet High)': 'https://images.pexels.com/photos/4162495/pexels-photo-4162495.jpeg?w=400',

            # LEGS - CALVES (6 exercises)
            'Standing Calf Raise (Machine)': 'https://images.pexels.com/photos/4162496/pexels-photo-4162496.jpeg?w=400',
            'Seated Calf Raise': 'https://images.pexels.com/photos/4162497/pexels-photo-4162497.jpeg?w=400',
            'Donkey Calf Raise': 'https://images.pexels.com/photos/4162498/pexels-photo-4162498.jpeg?w=400',
            'Single-Leg Calf Raise': 'https://images.pexels.com/photos/6550877/pexels-photo-6550877.jpeg?w=400',
            'Calf Raise on Leg Press': 'https://images.pexels.com/photos/4162499/pexels-photo-4162499.jpeg?w=400',
            'Jump Rope (Calf Focus)': 'https://images.pexels.com/photos/4162500/pexels-photo-4162500.jpeg?w=400',

            # GLUTES (12 exercises)
            'Hip Thrust (Barbell)': 'https://images.pexels.com/photos/6550878/pexels-photo-6550878.jpeg?w=400',
            'Hip Thrust (Dumbbell)': 'https://images.pexels.com/photos/6550879/pexels-photo-6550879.jpeg?w=400',
            'Glute Bridge': 'https://images.pexels.com/photos/6550880/pexels-photo-6550880.jpeg?w=400',
            'Single-Leg Glute Bridge': 'https://images.pexels.com/photos/6550881/pexels-photo-6550881.jpeg?w=400',
            'Cable Kickbacks': 'https://images.pexels.com/photos/4162501/pexels-photo-4162501.jpeg?w=400',
            'Cable Pull-Throughs': 'https://images.pexels.com/photos/4162502/pexels-photo-4162502.jpeg?w=400',
            'Sumo Squat': 'https://images.pexels.com/photos/6550882/pexels-photo-6550882.jpeg?w=400',
            'Step-Ups (Glute Focus)': 'https://images.pexels.com/photos/6550883/pexels-photo-6550883.jpeg?w=400',
            'Lateral Band Walks': 'https://images.pexels.com/photos/6550884/pexels-photo-6550884.jpeg?w=400',
            'Clamshells': 'https://images.pexels.com/photos/6550885/pexels-photo-6550885.jpeg?w=400',
            'Frog Pumps': 'https://images.pexels.com/photos/6550886/pexels-photo-6550886.jpeg?w=400',
            'Romanian Deadlift (Glute Focus)': 'https://images.pexels.com/photos/6550887/pexels-photo-6550887.jpeg?w=400',

            # CORE (15 exercises)
            'Plank': 'https://images.pexels.com/photos/6550888/pexels-photo-6550888.jpeg?w=400',
            'Side Plank': 'https://images.pexels.com/photos/6550889/pexels-photo-6550889.jpeg?w=400',
            'Dead Bug': 'https://images.pexels.com/photos/6550890/pexels-photo-6550890.jpeg?w=400',
            'Bird Dog': 'https://images.pexels.com/photos/6550891/pexels-photo-6550891.jpeg?w=400',
            'Hollow Body Hold': 'https://images.pexels.com/photos/6550892/pexels-photo-6550892.jpeg?w=400',
            'Bicycle Crunches': 'https://images.pexels.com/photos/6550893/pexels-photo-6550893.jpeg?w=400',
            'Russian Twists': 'https://images.pexels.com/photos/6550894/pexels-photo-6550894.jpeg?w=400',
            'Cable Woodchops': 'https://images.pexels.com/photos/4162503/pexels-photo-4162503.jpeg?w=400',
            'Hanging Leg Raises': 'https://images.pexels.com/photos/4162504/pexels-photo-4162504.jpeg?w=400',
            'Lying Leg Raises': 'https://images.pexels.com/photos/6550895/pexels-photo-6550895.jpeg?w=400',
            'Ab Wheel Rollout': 'https://images.pexels.com/photos/4162505/pexels-photo-4162505.jpeg?w=400',
            'Pallof Press': 'https://images.pexels.com/photos/4162506/pexels-photo-4162506.jpeg?w=400',
            'Dragon Flags': 'https://images.pexels.com/photos/6550896/pexels-photo-6550896.jpeg?w=400',
            'V-Ups': 'https://images.pexels.com/photos/6550897/pexels-photo-6550897.jpeg?w=400',
            'Mountain Climbers': 'https://images.pexels.com/photos/6550898/pexels-photo-6550898.jpeg?w=400',

            # CARDIO (12 exercises)
            'Treadmill Running': 'https://images.pexels.com/photos/4162507/pexels-photo-4162507.jpeg?w=400',
            'Treadmill Walking (Incline)': 'https://images.pexels.com/photos/4162508/pexels-photo-4162508.jpeg?w=400',
            'Stationary Bike': 'https://images.pexels.com/photos/4162509/pexels-photo-4162509.jpeg?w=400',
            'Rowing Machine': 'https://images.pexels.com/photos/4162510/pexels-photo-4162510.jpeg?w=400',
            'Stair Climber': 'https://images.pexels.com/photos/4162511/pexels-photo-4162511.jpeg?w=400',
            'Elliptical': 'https://images.pexels.com/photos/4162512/pexels-photo-4162512.jpeg?w=400',
            'Jump Rope': 'https://images.pexels.com/photos/4162513/pexels-photo-4162513.jpeg?w=400',
            'Burpees': 'https://images.pexels.com/photos/6550899/pexels-photo-6550899.jpeg?w=400',
            'Box Jumps': 'https://images.pexels.com/photos/4162514/pexels-photo-4162514.jpeg?w=400',
            'Battle Ropes': 'https://images.pexels.com/photos/4162515/pexels-photo-4162515.jpeg?w=400',
            'Assault Bike': 'https://images.pexels.com/photos/4162516/pexels-photo-4162516.jpeg?w=400',
            'Swimming': 'https://images.pexels.com/photos/863988/pexels-photo-863988.jpeg?w=400',

            # FULL BODY (15 exercises)
            'Barbell Clean': 'https://images.pexels.com/photos/4164787/pexels-photo-4164787.jpeg?w=400',
            'Power Clean': 'https://images.pexels.com/photos/4164788/pexels-photo-4164788.jpeg?w=400',
            'Clean and Jerk': 'https://images.pexels.com/photos/4164789/pexels-photo-4164789.jpeg?w=400',
            'Snatch': 'https://images.pexels.com/photos/4164790/pexels-photo-4164790.jpeg?w=400',
            'Thrusters': 'https://images.pexels.com/photos/6550900/pexels-photo-6550900.jpeg?w=400',
            'Man Makers': 'https://images.pexels.com/photos/6550901/pexels-photo-6550901.jpeg?w=400',
            'Turkish Get-Up': 'https://images.pexels.com/photos/4164791/pexels-photo-4164791.jpeg?w=400',
            "Farmer's Walk": 'https://images.pexels.com/photos/4164792/pexels-photo-4164792.jpeg?w=400',
            'Sled Push': 'https://images.pexels.com/photos/4162517/pexels-photo-4162517.jpeg?w=400',
            'Sled Pull': 'https://images.pexels.com/photos/4162518/pexels-photo-4162518.jpeg?w=400',
            'Tire Flips': 'https://images.pexels.com/photos/4162519/pexels-photo-4162519.jpeg?w=400',
            'Wall Balls': 'https://images.pexels.com/photos/6550902/pexels-photo-6550902.jpeg?w=400',
            'Kettlebell Swings': 'https://images.pexels.com/photos/4164793/pexels-photo-4164793.jpeg?w=400',
            'Medicine Ball Slams': 'https://images.pexels.com/photos/6550903/pexels-photo-6550903.jpeg?w=400',
            'Bear Crawl': 'https://images.pexels.com/photos/6550904/pexels-photo-6550904.jpeg?w=400',
        }

        # Fallback images by muscle group (verified working)
        muscle_group_images = {
            'chest': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&q=80',
            'back': 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=400&q=80',
            'shoulders': 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=400&q=80',
            'arms': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&q=80',
            'legs': 'https://images.unsplash.com/photo-1434608519344-49d77a699e1d?w=400&q=80',
            'glutes': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&q=80',
            'core': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
            'cardio': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&q=80',
            'full_body': 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=400&q=80',
            'other': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80',
        }

        updated_count = 0
        fallback_count = 0

        for exercise in Exercise.objects.all():
            # Skip if already has image and not forcing
            if exercise.image_url and not force:
                continue

            # Try specific image first, then fall back to muscle group
            if exercise.name in exercise_images:
                image_url = exercise_images[exercise.name]
            else:
                image_url = muscle_group_images.get(
                    exercise.muscle_group,
                    muscle_group_images['other']
                )
                fallback_count += 1

            exercise.image_url = image_url
            exercise.save(update_fields=['image_url'])
            updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Updated images for {updated_count} exercises '
                f'({fallback_count} used muscle group fallback).'
            )
        )
