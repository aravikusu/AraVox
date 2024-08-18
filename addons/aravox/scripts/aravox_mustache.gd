class_name AraVoxMustache extends Resource

enum MustacheType {
	FUNCTION = 0,
	DATA = 1,
	SHORTHAND = 2,
	NONE = 99
}

## The choices the player interacts with.
var type: MustacheType = MustacheType.NONE
## The name of the Mustache. The name of the "function", essentially.
var name: String = ""
## All of the "variables" specified inside of the Mustache.
var vars: Array[String] = []
## The full, majestic 'stache in its entirety.
var full_stache: String = ""
