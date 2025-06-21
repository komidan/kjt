
![trickyumpslogo](res/trickyumps_3.png)

# komi's Trickjumps
This plugin is meant to make trickjumping more popular by creating commands that enable sharing and managing jumps easier.

### Installation
Download the latest [release](https://github.com/komidan/ktj/releases), build from source, or to get the most up-to-date with all commits you can use `./addons/amxmodx/plugins/ktj.amxx` from source. It's kept up to date with every push I make, but keep in mind it's most likely unstable! Follow these steps once you have the plugin file:
1. Move `ktj.amxx` to `./Half-life/cstrike/addons/amxmodx/plugins/`.
2. Edit `.../addons/amxmodx/configs/plugins.ini` by adding `ktj.amxx` to the bottom of the file.
3. Launch Counter-Strike 1.6 to see if it worked. If not then... ask someone?

### Feature List
| Name             | Description                                                                                 | Status |
| ---------------- | ------------------------------------------------------------------------------------------- | :----: |
| Jump Management  | Ability to manage jumps. Saving, Deleting, and Setting.                                     |   🟢    |
| Jump List        | A menu that shows all saved jumps.                                                          |   🟢    |
| Jump Sharing     | By typing a command, receive an encoded string which you can load to create a jump locally. |   🔵    |
| Jump Measurement | Measure a start and end location for a jump to track if you land the jump or not?           |   ⚪    |

#### !!! NEED SUGGESTIONS, PLEASE GIVE ME JUICY SUGGESTIONS !!!

#### Legend
🟢 Finished\
🟡 In-Progress\
🔵 Need-Help\
⚪ Not-Started

### Commands
`/createjump <name>` - Creates a jump with \<name\> as a specifier.\
`/deletejump <name>` - Deletes a jump. Don't pass any arguments for delete list.\
`/setjump <name>` - Sets jump, teleports player to location. Don't pass any arguments for jump list.\
`/ktj` - About the plugin.

more on the way...