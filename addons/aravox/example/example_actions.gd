class_name ExampleActions extends Resource

## AraVox Actions have to be a Resource that you create, then send that .tres
## into aravox_config.tres.
## If anyone actually has an idea for handling this better, I'm all ears.
## An AraVox Action always has one prop, which is an Array of strings.
## These are the values you send put in the actual Mustache in the script.

## A simple action that just prints to the terminal.
func example_action(props: Array[String]) -> void:
	var str: String = ""
	for prop: String in props:
		str += prop + " "
	print(str)
