class_name AraVoxConfig extends Resource

## Shorthands are short keywords that AraVox will look for and replace with the specified value.
@export var shorthands: Dictionary
## The resource that contains all of your actions.[br][br]
## At the moment the only way I could think of to make this work is to have
## a Resource with all your functions, then a created .tres out of it exported
## to the configuration.
##[br][br]If there's a better way I'm all ears.
@export var actions: Resource
