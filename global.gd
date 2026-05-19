extends Node

# Order: Category -> Texture path and fact array -> split sentence/completed/in book stack (waiting to be shelved)
var facts: Dictionary = {
	"space": {
		"book_texture_path": "",
		"split_facts": [
			{
				"sentence": [],
				"in_stack": false,
				"completed": false
			}
		]
	},
	"history": {
		"book_texture_path": "",
		"split_facts": [
			{
				"sentence": [],
				"in_stack": false,
				"completed": false
			}
		]
	},
	"animals": {
		"book_texture_path": "",
		"split_facts": [
			{
				"sentence": [],
				"in_stack": false,
				"completed": false
			}
		]
	}
}
var book_stack: Array[Dictionary] = [] # Save the fact category when adding it to the stack book stack: {[fact, words]: "category"}