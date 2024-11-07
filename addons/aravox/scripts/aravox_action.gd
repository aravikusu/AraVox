class_name AraVoxAction extends Resource

## The actual function this action calls.
var function: Callable
## The function's properties, supplied by the script.
var func_props: Array[String]
## The line that will trigger this action.
var fired_after: int
## To let you know that we have in fact fired it already.
var fired: bool = false
## If it appears inside of a branch of a choice, this will be anything but -1.
var appears_in_branch: int = -1

func call_action() -> void:
	function.call(func_props)
	fired = true
