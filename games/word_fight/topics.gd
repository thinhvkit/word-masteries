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
	"body": [
		"arm","back","bone","brain","chest","chin","ear","elbow","eye","face",
		"finger","foot","hair","hand","head","heart","hip","jaw","knee","leg",
		"lip","lung","mouth","nail","neck","nose","palm","rib","shin","skin",
		"skull","spine","thumb","toe","tooth","wrist",
	],
	"weather": [
		"bolt","breeze","calm","chill","cloud","cold","dew","drizzle","dust",
		"flood","fog","frost","gale","gust","hail","heat","ice","mist","moon",
		"rain","sleet","slush","smog","snow","storm","sun","thaw","tide",
		"warm","wave","wind",
	],
	"clothing": [
		"belt","boot","cap","cape","cloak","coat","dress","fur","glove","gown",
		"hat","hood","jeans","lace","mask","mitt","robe","sash","scarf","shirt",
		"shoe","silk","skirt","sock","suit","tie","veil","vest","wool","wrap",
	],
	"home": [
		"bath","bed","bench","bowl","brick","broom","chair","clock","couch",
		"cup","desk","door","fence","floor","fork","frame","gate","glass",
		"hall","key","lamp","lock","mat","oven","paint","plate","roof","room",
		"shelf","sink","stair","stove","table","tile","wall","yard",
	],
	"sport": [
		"ball","bat","bike","boat","bowl","box","catch","climb","coach","court",
		"dart","dive","field","goal","golf","hit","jump","kick","lane","match",
		"net","oar","pass","pitch","pool","race","ring","row","run","sail",
		"score","shot","ski","spin","surf","swim","team","track",
	],
	"nature": [
		"bark","bay","bloom","branch","brook","bush","cave","cliff","creek",
		"dune","fern","field","flame","flow","glen","grass","grove","hill",
		"lake","leaf","log","marsh","moss","mud","oak","path","peak","pine",
		"pond","reef","ridge","river","rock","root","sand","sea","seed","shade",
		"shore","slope","soil","stone","stream","thorn","tree","vale","vine","wood",
	],
	"noun": [
		"age","air","art","bag","bank","bell","bill","bit","block","board",
		"bond","book","box","bridge","camp","card","case","cash","chain","chance",
		"charge","chip","claim","class","club","code","copy","core","cost","craft",
		"crew","crowd","deal","debt","dream","drive","drop","dust","fact","faith",
		"fate","fear","flag","flash","flight","force","fruit","fuel","fund","gain",
		"gap","gift","grade","grant","grip","guard","guide","hint","hook","host",
		"hunt","idea","iron","joke","judge","king","knot","label","land","layer",
		"lead","lens","lift","light","link","list","load","loan","loss","luck",
		"map","mark","mass","meal","mind","mine","mode","mood","myth","nest",
		"note","nurse","pack","pair","panel","park","part","patch","pause","peace",
		"phase","piece","pile","pitch","plan","plant","plot","plug","point","port",
		"post","pound","pride","prize","proof","pump","quest","quote","rank","rate",
		"realm","rent","rest","risk","role","root","rule","rush","sake","sale",
		"scale","scene","scope","sense","share","shift","ship","shock","sign","site",
		"skill","slot","smile","soul","source","spare","spell","spot","squad","stack",
		"staff","stage","stake","stand","state","steel","stem","step","stock","store",
		"strike","stuff","surge","tale","tank","tape","task","theme","tide","title",
		"tone","tool","tour","tower","trace","trade","trail","train","trait","trap",
		"trend","trick","trip","troop","trust","truth","tune","twist","unit","value",
		"verse","view","voice","vote","wage","waste","wealth","wheel","width","wing",
		"wire","wish","wound","zone",
	],
	"adjective": [
		"able","aged","bad","bare","big","bold","brave","brief","bright","broad",
		"calm","cheap","clean","clear","close","cold","cool","crude","cruel","cute",
		"dark","dead","deaf","dear","deep","dense","dim","dull","dumb","eager",
		"easy","evil","faint","fair","false","fast","fat","few","fierce","final",
		"fine","firm","fit","fixed","flat","fond","fool","foul","free","fresh",
		"full","glad","good","grand","grave","great","green","grim","gross","guilty",
		"hard","harsh","high","holy","hot","huge","humble","ill","keen","kind",
		"large","late","lazy","lean","light","live","lone","long","loose","lost",
		"loud","low","lucky","mad","main","male","mean","mere","mild","minor",
		"moist","moral","naked","narrow","neat","noble","odd","old","open","pale",
		"plain","plump","polite","poor","prime","prior","proud","pure","quick",
		"quiet","rare","raw","real","rich","rigid","ripe","rough","round","royal",
		"rude","rural","sad","safe","salty","scared","sharp","short","shy","sick",
		"silly","slim","slow","small","smart","smooth","soft","solid","sore","spare",
		"steep","stern","stiff","still","strange","strict","strong","subtle","super",
		"sure","sweet","swift","tall","tame","thick","thin","tight","tiny","tired",
		"tough","true","ugly","unique","upper","upset","vague","valid","vast","vital",
		"vivid","warm","weak","weird","wet","whole","wide","wild","wise","wrong",
		"young",
	],
	"verb": [
		"act","add","aim","ask","ban","bear","beat","bend","bet","bid",
		"bind","bite","blow","boil","bore","bow","break","breed","bring","build",
		"burn","burst","buy","call","carry","carve","cast","catch","chase","cheat",
		"check","chew","chop","claim","clap","clean","climb","cling","close","coach",
		"cook","cope","cost","count","crack","crash","crawl","cross","crush","cure",
		"cut","dare","deal","dig","dip","drag","drain","draw","dream","dress",
		"drift","drill","drink","drive","drop","dry","dump","earn","eat","edit",
		"face","fade","fail","fall","fear","feed","feel","fetch","fight","fill",
		"find","fire","fit","fix","flee","flip","float","fold","force","forge",
		"form","found","frame","free","freeze","frown","fry","gain","gaze","get",
		"give","glow","go","grab","grant","grasp","greet","grin","grip","grow",
		"guard","guess","guide","halt","hang","harm","hate","haul","heal","hear",
		"heat","help","hide","hire","hit","hold","hope","hug","hunt","hurt",
		"join","judge","jump","keep","kick","kill","kiss","kneel","knit","knock",
		"know","land","last","laugh","lay","lead","lean","leap","learn","leave",
		"lend","let","lie","lift","light","like","limit","link","live","load",
		"lock","look","lose","love","make","mark","match","mean","meet","melt",
		"merge","mind","miss","mix","moan","mock","mount","move","name","nod",
		"note","obey","pack","paint","pass","pause","pay","peel","pick","pile",
		"pitch","place","plan","plant","play","plead","plot","pluck","plug","point",
		"poke","polish","pour","pray","press","print","pull","pump","punch","push",
		"put","quit","race","raise","reach","read","rely","rest","ride","ring",
		"rise","risk","rob","rock","roll","rub","ruin","rule","run","rush",
		"save","say","seal","seek","seize","sell","send","serve","set","shake",
		"shape","share","shed","shift","shine","shock","shoot","shout","show","shut",
		"sign","sing","sink","sit","skip","slam","sleep","slice","slide","slip",
		"smell","smile","snap","soak","solve","sort","spark","speak","speed","spend",
		"spill","spin","split","spoil","spot","spray","spread","spy","stab","stack",
		"stain","stand","stare","start","stay","steal","steer","step","stick","sting",
		"stir","stop","store","strip","stroke","study","stuff","suck","sue","suit",
		"sum","supply","surge","swallow","swap","swear","sweep","swim","swing","take",
		"talk","tap","taste","teach","tear","tell","tend","test","thank","think",
		"throw","tie","tip","toast","toss","touch","trace","trade","trail","train",
		"trap","treat","trick","trim","trip","trust","try","tuck","tug","turn",
		"twist","type","urge","use","value","vary","vote","wade","wake","walk",
		"wander","warn","wash","waste","watch","wave","wear","weave","weigh","weld",
		"whip","win","wipe","wish","wonder","work","worry","wrap","write","yawn","yell",
	],
}

static func has(topic: String, word: String) -> bool:
	var key := topic.to_lower()
	if not TOPICS.has(key):
		return false
	if TOPICS[key].is_empty():
		return false
	return word.to_lower() in TOPICS[key]

static func random_topic() -> String:
	var keys := TOPICS.keys()
	keys.erase("noun")
	return keys[randi() % keys.size()]
