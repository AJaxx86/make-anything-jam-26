# TODO
[X] Add interactables, make sure clicking brings up UI and/or moves and zooms the camera
[X] Add FactBuilder UI
[X] Add editable labels
[-] Add bookshelf logic for placing books, as well as opening the books so the player can re-read the fact
	^Still needs UI
[X] Change the table scene so clicking the table zooms, then clicking an empty book opens the FactBuilder
[X] Add book stack to table scene for completed books
[X] Add delay when entering the bookshelf so books aren't immediately added (3D scene with book and UI spawns in front of player cam)
[X] Fix bug regarding not enough facts being added to FactBuilder
[X] Fix bug where FactBuilder gets empty facts
[X] Make FactBuilder reset only when finishing all facts that were given, then add more facts instead of whenever it's opened
[X] Update FactBuilder to remove false fact pieces when the fact is complete

# CONTROLS
ESC - Tap to go back, hold to pause
LEFT CLICK - Interact

# FACTS
- sea (blue)
- plants (green)
- creatures (brown)
- sky (white)
- science (red)
- space (black)
- history (yellow)
- sea plants (aqua green)
- human (pink)

Click the opened empty book, which opens the FactBuilder UI containing 7 random facts which are split up. The player then chooses words to put together the sentence. once correct, the book colour updates based on the category of fact, and the 2 pages fill with details (left side the fact sentence, right side more details) then the player puts books from the stack on the shelf. If there's time, the book cover has art based on the category too.
