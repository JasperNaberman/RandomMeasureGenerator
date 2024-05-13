# RandomMeasureGenerator
Application deployed at: https://jnaberman.shinyapps.io/random_measure_generator/


Generates random 4 count musical measures where each count consists of either a quarter note or any combination of 2 notes that would result in a unique rhythmic timing.
Given those constraints, only 7 options are possible for a count:
- "quarter note"
- "8th note - 8th note"
- "16th note - dotted 8th note"
- "dotted 8th note - 16th note"
- "8th rest - 16th note - 16th note"
- "16th rest - 16th note - 16th rest - 16th note"
- "16th rest - 16th note - 16th note - 16th rest"

Given 7 options per count, and 4 counts in a standard measure, that leaves us with 7^4 = 2401 unique measures.

This app randomly samples one of those measures and displays it visually for the user to practice with.
Alongside this visual functionality, also some audio features are included, like a simple metronome, and the ability to let the app play the displayed rhythmic pattern.

The sampling of measures does not happen completely random, but within user difficulty categories the user can choose.
The difficulty of a measure is determined by the sum of its counts, where each count gets its own difficulty score:

- "quarter note" = 1
- "8th note - 8th note" = 2
- "16th note - dotted 8th note" = 3
- "dotted 8th note - 16th note" = 3
- "8th rest - 16th note - 16th note" = 4
- "16th rest - 16th note - 16th rest - 16th note" = 5
- "16th rest - 16th note - 16th note - 16th rest" = 5

So if a measure consists of the counts | "dotted 8th note - 16th note" | "8th rest - 16th note - 16th note" | "8th note - 8th note" | "8th note - 8th note" | its difficulty score would be 3 + 4 + 2 + 2 = 11.
If however, the measure contains only 1 or 2 unique counts, 2 points are subtracted from the difficulty score. Similarly, if a measure has 4 unique counts, a 2 points are added to the final score.
For example, the measure | "dotted 8th note - 16th note" | "8th rest - 16th note - 16th note" | "16th note - dotted 8th note" | "8th note - 8th note" | would be 12 points usually, but since it contains 4 unique counts, the final score ends up as 12 + 2 = 14.

These difficulty scores are then rescaled into categories, where:
- <= 10 points: easy
- > 10 points <= 14 points: medium
- > 14 points: hard
