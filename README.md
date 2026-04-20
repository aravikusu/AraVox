# AraVox for Godot
AraVox is an plugin for Godot that aims to aid in writing dialogue for your game. It uses a syntax heavily inspired by [handlebars.js](https://github.com/handlebars-lang/handlebars.js) to allow writers to write dialogue for your game, using data and functions, giving them "control" in the script rather than having to hand-hold the programmer the entire way to get it "just right". That's the idea, anyways.

I recommend checking out the [wiki](https://github.com/aravikusu/AraVox/wiki) for more information regarding how to use AraVox.

AraVox is made for Godot 4.

Current Version: 2.0.0

## Changelog
### 2.0.0
More or less a complete overhaul of the plugin. Check the releases for a full changelog.

### 1.2.1
This update fixes actions when they are nested inside of a choice branch.

### 1.2.0
This update unfortunately come with a breaking change with the rename of AraVoxShorthands -> AraVoxConfig. This resource now also lets you specify a Resource that contains your Actions.
- Added the #action Mustache.
