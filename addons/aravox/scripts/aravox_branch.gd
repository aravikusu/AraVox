class_name AraVoxBranch extends Resource

## The actual text in this branch.
var branch: Array[String]
## If the branch has any choices in it, they go here.
var choices: Array[AraVoxChoice]
## If the branch has any actions in it, they go here.
var actions: Array[AraVoxAction]