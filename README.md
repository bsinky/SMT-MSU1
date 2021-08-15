Shin Megami Tensei MSU-1 patch
==============================

This is an assembly patch for Shin Megami Tensei on the Super Famicom to enable MSU-1 audio support.

Building
--------

Assemble with [asar](https://github.com/RPGHacker/asar). Tested against version 1.8, might work on earlier versions.

It has been tested against the following ROMs and should be compatible, but may be compatible with other patches as well:

 - Shin Megami Tensei (J) (V1.0) [!]
   - MD5: 9055814b1782cadd538c78ae773826b8
   - SHA256: d0b5eac22d9e07c4a7ca10387200408bed0e635684cecc98ad008824e2952a6a
   - CRC32: 90DE2C78

 - Shin Megami Tensei (J) (V1.0) [T+Eng1.00_AGTP,Bugfixes1.0_Orden,AutomapENH1.0_Revenant]
   - MD5: f3f2c71227399931fbcb09e1b4e27f46
   - SHA256: 90098967e2f2109c8bf72dbff36e8c140dfd110e2479f6049fa4babc4ddab4e6
   - CRC32: 9A7035AB

Adjustable Settings
-------------------

There are a few variables in the code you can tweak before assembling:

 - `!EnableMultipleBattleThemes`, default is `!True`, set to `!False` if you just want the default battle music to play during encounters
    - When this is `!True`, the battle theme will be "randomly" selected whenever battle music plays
 - `!NumBattleThemes`, default is 4, this allows for 3 extra battles tracks.
    - You can set this to a higher power of 2 if you want even more extra battle tracks.
    - If `!EnableMultipleBattleThemes` is `!False` this setting is ignored

MSU-1 track listing
-------------------

All tracks are set to loop except for Ending, but you can also treat Demo as non-looping since it plays for a very short time before it is stopped.

"Enemy Appear" appears multiple times with a different sound effect playing during the intro. Since the SPC audio for those tracks includes the sound effect at the start, the easiest way to work around this was to make them separate PCM tracks and bake the requisite sound effect into the track.

1. Enemy Appear (no intro)
2. Enemy Appear (39 version)
3. Enemy Appear (3A version)
4. Enemy Appear (3B version)
5. Battle
6. Level Up
7. Enemy Appear (3F version)
8. Enemy Appear (42 version)
9. Enemy Appear (43 version)
10. Mansion of Heresey
11. Law
12. Chaos
13. Neutral
14. Ginza
15. Cathedral
16. Shibuya
17. Palace of the Four Heavenly Kings
18. Embassy
19. Arcade Street
20. Kichijoji
21. Ruins
22. Shop
23. Boss Battle
24. Dream
25. Home
26. Pascal
27. Unknown Song (Unused)
28. Game Over
29. Terminal
30. Epilogue
31. Demo
32. Title
33. Fusion
34. Ending

If multiple battle tracks are enabled, the extra tracks go at the end. Ex.: if using the default 3 extra battle tracks, you should also provide PCM tracks 35, 36, and 37.

Known Issues
------------

If running on an emulator that supports MSU-1 but there's a PCM track missing, fallback to SPC audio is working but the SPC audio will sometimes not stop when the next MSU-1 track begins playing, causing the MSU-1 and SPC music to overlap.
