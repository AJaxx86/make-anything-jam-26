extends Node

var facts: Dictionary[String, Array] = {
	"space": [],
	"history": [],
	"animals": [],
}
var book_stack: Array[Dictionary] = [] # Save the fact category when adding it to the stack book stack: {[fact, words]: "category"}
