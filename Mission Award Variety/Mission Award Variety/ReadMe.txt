------------------------------------------------
Mission Award Variety - an XCOM 2 Mod by atamize
Version 1.3.0
------------------------------------------------

Adds more interesting awards on the mission debriefing screen.

[b]HATES 'X' THE MOST[/b]
Dealt the most damage to the particular enemy type that was damaged the most

[b]LUCKIEST[/b]
Hit the most unlikely shots and dodged the most likely incoming shots

[b]SOLO SLAYER[/b]
Murdered the most ayys without help from teammates

[b]POWER COUPLE[/b]
The two soldiers who did the most damage while double-teaming enemies

[b]UNLUCKIEST[/b]
Missed the most likely shots and got hit by the most unlikely incoming shots

[b]HEAVY HITTER[/b]
Dealt the most critical hit damage

[b]MOST ASSISTS[/b]
Dealt the most damage that did not result in a kill

[b]KILL STEALER[/b]
Finished off the most enemies previously damaged by others

[b]AIN'T GOT TIME TO BLEED[/b]
Dealt the most damage while wounded

[b]NOT BAD, KID[/b]
Lowest ranking soldier who did more damage than a higher ranking soldier

[b]TOO OLD FOR THIS $#!@[/b]
Highest ranking soldier who got shot at or damaged the most

[b]LOVES BEING A TURTLE[/b]
Overwatched or hunkered down the most

[b]MOST HIGH[/b]
Took the most shots with a height advantage

[b]CLOSE RANGE?[/b]
Dealt the most damage at...close range

[b]LEAF ON THE WIND[/b]
Ran the most overwatches (bonus points if you didn't get hit)

[b]MISS (OR MISTER) CONGENIALITY[/b]
Didn't win any awards but still contributed to the mission. If won by an alien, this will appear as [b]EFFECTIVE DEFECTOR[/b], or [b]BIT PLAYER[/b] if won by a mec.

[b]UNFINISHED BUSINESS[/b]
Fought the hardest after a teammate died/evacuated/incapacitated

[b]LITERALLY THE WORST[/b]
Didn't win any awards and dealt the least amount of damage

[b]OVERQUALIFIED[/b]
Got the most kills relative to their rank (higher ranks expected to have more kills)

[b]SNEAKIEST[/b]
Moved the furthest while in concealment

[b]HOME WRECKER[/b]
Caused the most environmental damage (includes breaking windows, doors, and errant shots)

[b]MOST KILLS IN A TURN[/b]
Must have at least 2 kills in a turn to qualify

[b]MOST EXPOSED[/b]
Ended the most turns with sight on the most enemies while in lightest cover

[b]RUNNING ON EMPTY[/b]
Ended the most turns without reloading with no ammo in primary weapon


[h1]CONFIGURATION OPTIONS[/h1]
These options are found in XComMissionAwardVariety.ini:

[b]ShowVanillaStats[/b] - If set to true, the left column will show the vanilla team stats (Successful Shot Percentage, etc.) and the right column will show 4 random awards. If set to false (by default), 8 random awards will be shown if there are enough winners.

[b]IncludeVanillaAwards[/b] - If set to true, the vanilla awards will be included in the award pool (Dealt Most Damage, Made Most Attacks, Most Under Fire, Moved Furthest).

[h1]FAQ[/h1]
[b]Q: I have an idea for an award, can you add it to your mod?[/b]
A: Maybe, depending on how interesting it is and how easy it is to track.

[b]Q: Can I change the names of the awards?[/b]
A: Sure! Just open Localization/MissionAwardVariety.int (or your preferred language file) in a text editor and edit away. 

[b]Q: How is luck calculated?[/b]
A: Whenever a soldier makes a successful shot, (100 - ChanceToHit) is added to their luck value. Whenever they dodge enemy fire, ChanceToHit is added to their luck value.

[b]Q: How come I haven't seen some of these awards?[/b]
The screen can only fit 8 awards at a time and the ones you see are randomized. Also, some categories may not have a winner and will not be shown.

[b]Q: Your translations are wrong; can I give you the correct translations?[/b]
Yes, please! Just post your translations in the discussion thread.

[b]Q: Any compatibility issues?[/b]
A: Does not override any classes so it should work with any mod except for those that override UIDropShipBriefing_MissionEnd such as [url=http://steamcommunity.com/sharedfiles/filedetails/?id=638033072]Nice DropShip (De)Briefing[/url]. There is support planned for compatibility with this mod so stay tuned.

[b]Q: Wouldn't it be cool if you could name your mind-controlled enemies so their names could show up on this screen instead of their boring template names?[/b]
A: Yeah, it would! In fact, I made a mod that will make your wish come true: [url=http://steamcommunity.com/sharedfiles/filedetails/?id=677029871]Name Your Pet[/url]

[b]Q: Do I have to start a new campaign before installing this mod?[/b]
A: No, you can insert it into an existing campaign.

Thanks to Kosmo for the [url=http://steamcommunity.com/sharedfiles/filedetails/?id=634754304]Lifetime Stats[/url] mod whose code was very helpful in setting this up.