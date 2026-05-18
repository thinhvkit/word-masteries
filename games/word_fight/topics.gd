class_name WFTopics
## Simple topic→word membership lookup for Word Fight topic bonus.
## Small curated lists; extend as the dictionary grows.

const TOPICS := {
	"food": [
		"apple","bread","cake","cheese","corn","egg","eggs","fish","grape",
		"ham","honey","jam","lamb","meat","melon","milk","oat","oats","onion",
		"orange","peach","pear","pie","pita","plum","rice","salad","salt",
		"soup","steak","stew","sugar","taco","tea","toast","wheat","yam",
	],
	"animal": [
		"ant","ape","bat","bear","bee","bird","boar","bug","cat","cod","cow",
		"crab","crow","deer","dog","dove","duck","eel","elk","emu","ewe",
		"fish","fox","frog","goat","hare","hen","hog","horse","ibis","koala",
		"lamb","lion","mole","moth","mule","newt","owl","ox","panda","pig",
		"pony","pup","rat","ram","robin","seal","sheep","skunk","snail",
		"snake","swan","tiger","toad","trout","tuna","wasp","wolf","worm","yak","zebra",
	],
	"shape": [
		"arc","arch","ball","band","bar","bend","circle","cone","cube","curl",
		"curve","cylinder","disc","dot","edge","heart","line","loop","oval",
		"path","pole","ring","rod","sphere","spike","spine","spiral","square",
		"star","strip","tile","tip","tube","wedge","whorl",
	],
	"color": [
		"amber","azure","beige","black","blue","brown","coral","cream","cyan",
		"gold","gray","green","ivory","jade","khaki","lemon","lime","mauve",
		"navy","ochre","olive","orange","peach","pink","plum","purple","red",
		"rose","ruby","rust","sage","scarlet","silver","tan","teal","violet","white","yellow",
	],
	"noun": [],  # any word treated as noun-friendly; falls through to no-bonus
}

static func has(topic: String, word: String) -> bool:
	var key := topic.to_lower()
	if not TOPICS.has(key):
		return false
	if key == "noun":
		return false  # no automatic noun classification — bonus disabled for generic topic
	return word.to_lower() in TOPICS[key]

static func random_topic() -> String:
	var keys := ["food", "animal", "shape", "color"]
	return keys[randi() % keys.size()]
