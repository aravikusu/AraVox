class_name AraVoxChoice extends Resource

## The choices the player interacts with.
var options: Array[String] = []
## An Array that contains an Array of strings...
## Godot doesn't have support for this typing.
var branches: Array
## The line where this choice actually appears on.
var appears_on: int = 0
## If it appears inside of an existing branch, this will be anything but -1.
var appears_in_branch: int = -1
