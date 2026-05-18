class_name Artboards
extends RefCounted
## Static factory: one function per wireframe artboard.
## Each returns a populated `WF.Phone` Control (340×720).

const W := 340
const H := 720

# ─────────── ONBOARDING ───────────

static func splash() -> Control:
	var p := WF.Phone.new()
	var body := p.padded_body(Vector4(32, 0, 32, 0), 20)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var center_holder := CenterContainer.new()
	center_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center_holder)
	center_holder.add_child(WF.rainbow_block("W", 100, 24))
	body.add_child(_center_label("Word Masteries", 38, WF.TEXT, true))
	body.add_child(_center_label("Master words, conquer games", 20, WF.MUTED))
	body.add_child(_v_spacer(24))
	body.add_child(WF.wf_btn("Get Started", true))
	body.add_child(_center_label("Already have an account? Log in", 18, WF.ACCENT))
	body.add_child(_v_spacer(32))
	return p

static func login() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Log In"))
	var body := p.padded_body(Vector4(24, 24, 24, 24), 16)
	body.add_child(_center_label("Welcome Back!", 28, WF.TEXT, true))
	body.add_child(_center_label("Enter your details to continue", 18, WF.MUTED))
	body.add_child(WF.wf_input("Email address"))
	body.add_child(WF.wf_input("Password"))
	body.add_child(WF.wf_btn("Log In", true))
	body.add_child(WF.divr("or"))
	body.add_child(WF.wf_btn("Continue with Google", false, true))
	body.add_child(WF.wf_btn("Continue with Apple", false, true))
	var sign := _center_label("Don't have an account? Sign Up", 16, WF.MUTED)
	body.add_child(sign)
	return p

static func name_entry() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Set Up", true))
	var body := p.padded_body(Vector4(24, 24, 24, 24), 20)
	body.add_child(_center_label("What's your name?", 28, WF.TEXT, true))
	body.add_child(_center_label("This is how you'll appear in the game", 18, WF.MUTED))
	body.add_child(WF.wf_input("Enter your name...", "Alex"))
	# Avatar grid
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var avatars := ["🦊","🐼","🦁","🐸","🦉","🐱","🐶","🐯"]
	for i in avatars.size():
		grid.add_child(_avatar_tile(avatars[i], i == 0))
	body.add_child(grid)
	body.add_child(_v_spacer(60))
	body.add_child(WF.wf_btn("Continue", true))
	return p

static func mode_select() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Choose Mode", true))
	var body := p.padded_body(Vector4(24, 24, 24, 24), 16)
	body.add_child(_center_label("Choose your level", 28, WF.TEXT, true))
	body.add_child(_center_label("This sets difficulty for all games", 18, WF.MUTED))
	# Intermediate (selected)
	body.add_child(_mode_card("Intermediate", "Shorter words, simpler prompts. Great for building confidence.", true))
	body.add_child(_mode_card("Advanced", "Longer words, complex grammar. A real challenge.", false))
	body.add_child(WF.note("You can change this anytime in Settings"))
	body.add_child(_v_spacer(40))
	body.add_child(WF.wf_btn("Start Playing", true))
	return p

# ─────────── HUB ───────────

static func hub_a() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Masteries", false, "Intermediate", "⚙"))
	p.set_bottom_nav(WF.bottom_nav(["Map","Stats","Profile","Settings"], 0))
	var body := p.padded_body(Vector4(24, 16, 24, 16), 16)
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 32)
	top_row.add_child(WF.score_box("Total", "1,250"))
	top_row.add_child(WF.score_box("Streak", "5 🔥"))
	body.add_child(top_row)
	# Vertical path
	var path_box := VBoxContainer.new()
	path_box.add_theme_constant_override("separation", 16)
	var nodes := [
		{"name": "Word Fight", "icon":"⚔", "done": true},
		{"name": "Word Match", "icon":"🔗", "done": true},
		{"name": "Word Found", "icon":"🔍", "active": true},
		{"name": "Story Tell", "icon":"📖"},
		{"name": "Word Type", "icon":"🔤"},
		{"name": "Describe Pic", "icon":"🖼"},
		{"name": "Listen", "icon":"🎧"},
	]
	for n in nodes:
		path_box.add_child(_path_node(n))
	body.add_child(path_box)
	return p

static func hub_b() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Masteries", false, "Advanced", "⚙"))
	p.set_bottom_nav(WF.bottom_nav(["Map","Stats","Profile","Settings"], 0))
	var body := p.padded_body(Vector4(16, 16, 16, 16), 12)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 20)
	top.add_child(WF.pill("🏆 1,250 pts", WF.TEXT, WF.PAPER))
	top.add_child(WF.pill("🔥 5 day streak", WF.TEXT, WF.PAPER))
	body.add_child(top)
	# Winding nodes (alternating x position to fake the path)
	var nodes := [
		{"name":"Word Fight","icon":"⚔","done":true,"right":false},
		{"name":"Word Match","icon":"🔗","done":true,"right":true},
		{"name":"Word Found","icon":"🔍","active":true,"right":false},
		{"name":"Story Tell","icon":"📖","right":true},
		{"name":"Word Type","icon":"🔤","right":false},
		{"name":"Describe Pic","icon":"🖼","right":true},
		{"name":"Listen","icon":"🎧","right":false},
	]
	for n in nodes:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 0)
		if n.get("right", false):
			h.add_child(_h_spacer_expand())
			h.add_child(_winding_node(n))
		else:
			h.add_child(_winding_node(n))
			h.add_child(_h_spacer_expand())
		body.add_child(h)
	return p

static func hub_c() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Masteries", false, "Intermediate", "⚙"))
	p.set_bottom_nav(WF.bottom_nav(["Map","Stats","Profile","Settings"], 0))
	var body := p.padded_body(Vector4(16, 16, 16, 16), 12)
	var greet_row := HBoxContainer.new()
	greet_row.add_theme_constant_override("separation", 8)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(WF.make_label("Hey, Alex!", 28, WF.TEXT, true))
	left.add_child(WF.make_label("Keep your streak going", 16, WF.MUTED))
	greet_row.add_child(left)
	var streak_box := VBoxContainer.new()
	streak_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var s1 := WF.make_label("5🔥", 28, WF.WARN, true)
	s1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_box.add_child(s1)
	var s2 := WF.make_label("day streak", 13, WF.MUTED)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_box.add_child(s2)
	greet_row.add_child(streak_box)
	body.add_child(greet_row)
	body.add_child(WF.hp_bar(3, 5, WF.SUCCESS, "Daily Goal", true, 10))
	body.add_child(WF.make_label("3/5 games completed today", 14, WF.MUTED))
	body.add_child(WF.make_label("Your Journey", 20, WF.TEXT, true))
	var games := [
		{"name":"Word Fight","icon":"⚔","desc":"Battle enemies with words","active":true},
		{"name":"Word Match","icon":"🔗","desc":"Drag to connect letters","active":true},
		{"name":"Word Found","icon":"🔍","desc":"Find hidden words in rows","active":true},
		{"name":"Story Tell","icon":"📖","desc":"Complete the story","active":true},
		{"name":"Word Type","icon":"🔤","desc":"Find all forms of a word","active":true},
		{"name":"Describe Picture","icon":"🖼","desc":"Complete sentence starters","active":true},
		{"name":"Listen & Dictate","icon":"🎧","desc":"Hear the word, type it","active":true},
	]
	for g in games:
		body.add_child(_game_card(g))
	return p

# ─────────── WORD FIGHT ───────────

static func wf_intro() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Fight", true, "Intermediate"))
	var body := p.padded_body(Vector4(24, 32, 24, 32), 20)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_center_label("Round 1", 28, WF.TEXT, true))
	var vs_row := HBoxContainer.new()
	vs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vs_row.add_theme_constant_override("separation", 24)
	vs_row.add_child(WF.avatar("You", 64))
	vs_row.add_child(WF.make_label("VS", 32, WF.MUTED, true))
	vs_row.add_child(WF.avatar("Goblin", 64, true))
	body.add_child(vs_row)
	var topic_card := WF.card(WF.WARN_BG, WF.WARN, 12, 12, 2)
	var topic_box := VBoxContainer.new()
	topic_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var t1 := WF.make_label("Topic", 14, WF.MUTED)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic_box.add_child(t1)
	var t2 := WF.make_label("Food 🍕", 24, WF.TEXT, true)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic_box.add_child(t2)
	topic_card.add_child(topic_box)
	body.add_child(topic_card)
	body.add_child(WF.note("Words matching the topic deal ×2 damage!"))
	body.add_child(WF.wf_btn("Start Battle!", true))
	return p

static func wf_game_a() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Fight", true, "Food"))
	var body := p.padded_body(Vector4(12, 12, 12, 12), 8)
	body.add_child(_hp_row(WF.avatar("", 32), WF.hp_bar(80, 100, WF.SUCCESS, "", true, 12)))
	body.add_child(_hp_row(WF.avatar("", 32, true), WF.hp_bar(55, 100, WF.DANGER, "", true, 12)))
	# Current word
	var word_card := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 12, 2)
	var word_row := HBoxContainer.new()
	word_row.alignment = BoxContainer.ALIGNMENT_CENTER
	word_row.add_theme_constant_override("separation", 6)
	word_row.add_child(WF.make_label("Your word:", 14, WF.MUTED))
	word_row.add_child(WF.make_label("CHAT", 24, WF.ACCENT, true))
	word_row.add_child(WF.make_label("+40 dmg", 14, WF.SUCCESS))
	word_card.add_child(word_row)
	body.add_child(word_card)
	# 5×5 board
	var board_card := WF.card(WF.PAPER, WF.BORDER, 8, 16, 2)
	var board := GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 6)
	board.add_theme_constant_override("v_separation", 6)
	var letters_a := "STARE PLOWN ICHAT BRUSK DEFGM".replace(" ", "")
	for i in 25:
		var sel := i == 12 or i == 13 or i == 14
		var rb := i == 18
		board.add_child(WF.tile(letters_a[i], sel, rb, false, 48))
	board_card.add_child(board)
	body.add_child(board_card)
	# Boosters row
	var boost := HBoxContainer.new()
	boost.add_theme_constant_override("separation", 6)
	boost.add_child(WF.streak_dots(3, 4))
	boost.add_child(_h_spacer_expand())
	boost.add_child(WF.make_label("Boosters:", 14, WF.MUTED))
	boost.add_child(_mini_rainbow_tile())
	boost.add_child(_empty_slot())
	boost.add_child(_empty_slot())
	body.add_child(boost)
	# Submit row
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var clear_btn := WF.wf_btn("Clear", false, true)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(clear_btn)
	var sub_btn := WF.wf_btn("Submit Word", true)
	sub_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(sub_btn)
	body.add_child(actions)
	# Turn log
	var log_card := WF.card(Color("#f5f5f3"), Color(0,0,0,0), 8, 8, 0)
	var log_box := VBoxContainer.new()
	log_box.add_child(WF.make_label("You: \"PLOW\" → 40 dmg", 14, WF.MUTED))
	log_box.add_child(WF.make_label("Goblin: \"STAR\" → 30 dmg", 14, WF.MUTED))
	log_card.add_child(log_box)
	body.add_child(log_card)
	return p

static func wf_game_b() -> Control:
	var p := WF.Phone.new(true)  # dark mode
	var body := p.padded_body(Vector4(12, 12, 12, 12), 10)
	# Top enemy
	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 10)
	enemy_row.add_child(WF.avatar("", 44, true))
	var ebox := VBoxContainer.new()
	ebox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebox.add_child(WF.make_label("Dragon Lv.3", 16, WF.DANGER, true))
	ebox.add_child(WF.hp_bar(35, 100, WF.DANGER, "", false, 10))
	enemy_row.add_child(ebox)
	body.add_child(enemy_row)
	# Topic banner
	var topic := WF.card(Color(WF.WARN.r, WF.WARN.g, WF.WARN.b, 0.15), WF.WARN, 4, 8, 1)
	var t_lbl := WF.make_label("⚡ Topic: Animals — ×2 bonus", 15, WF.WARN)
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic.add_child(t_lbl)
	body.add_child(topic)
	# Dark board
	var board_card := WF.card(WF.DARK_PAPER, Color("#334"), 10, 16, 2)
	var board := GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 5)
	board.add_theme_constant_override("v_separation", 5)
	var letters_b := "TRAINSECOPHUMBLADOWKFEGIY".substr(0, 25)
	for i in 25:
		# Dark tiles — render as plain dark squares with letter
		var t := _dark_tile(letters_b[i], i in [0,1,2,3], i == 7)
		board.add_child(t)
	board_card.add_child(board)
	body.add_child(board_card)
	# Word forming
	var word_card := WF.card(Color(WF.ACCENT.r, WF.ACCENT.g, WF.ACCENT.b, 0.15), WF.ACCENT, 6, 10, 2)
	var word_row := HBoxContainer.new()
	word_row.alignment = BoxContainer.ALIGNMENT_CENTER
	word_row.add_theme_constant_override("separation", 6)
	word_row.add_child(WF.make_label("TRAIN", 22, WF.ACCENT, true))
	word_row.add_child(WF.make_label("+100 dmg (×2!)", 14, WF.SUCCESS))
	word_card.add_child(word_row)
	body.add_child(word_card)
	# Player row
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	prow.add_child(WF.avatar("", 44))
	var pbox := VBoxContainer.new()
	pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbox.add_child(WF.make_label("Alex", 16, WF.ACCENT, true))
	pbox.add_child(WF.hp_bar(70, 100, WF.ACCENT, "", false, 10))
	prow.add_child(pbox)
	prow.add_child(_mini_rainbow_tile())
	prow.add_child(_empty_slot(Color("#2a2a4e"), Color("#334")))
	body.add_child(prow)
	# Submit
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var clear_btn := WF.wf_btn("Clear", false, true)
	clear_btn.add_theme_color_override("font_color", Color("#aaa"))
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(clear_btn)
	var sub_btn := WF.wf_btn("Submit", true)
	sub_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(sub_btn)
	body.add_child(actions)
	return p

static func wf_rainbow() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Fight", true, "Food"))
	var body := p.padded_body(Vector4(12, 12, 12, 12), 10)
	body.add_child(_hp_row(WF.avatar("", 32), WF.hp_bar(60, 100, WF.SUCCESS, "", true, 10)))
	body.add_child(_hp_row(WF.avatar("", 32, true), WF.hp_bar(25, 100, WF.DANGER, "", true, 10)))
	# Instruction
	var card := WF.card(Color("#FFD93D22"), WF.PURPLE, 10, 12, 2)
	var card_box := VBoxContainer.new()
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var t1 := WF.make_label("🌈 Place your Rainbow Tile!", 18, WF.PURPLE, true)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(t1)
	var t2 := WF.make_label("Tap a board position to place it", 14, WF.MUTED)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(t2)
	card.add_child(card_box)
	body.add_child(card)
	# Board
	var board_card := WF.card(WF.PAPER, WF.BORDER, 8, 16, 2)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var letters := "MEALSPICKOFR★THBUNDGWAYEL".substr(0, 25)
	for i in 25:
		var l := letters[i]
		grid.add_child(WF.tile(l, i in [7, 8, 16], i == 12, false, 48))
	board_card.add_child(grid)
	body.add_child(board_card)
	# Boosters left
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 6)
	bottom.add_child(WF.make_label("Boosters left:", 14, WF.MUTED))
	bottom.add_child(_mini_rainbow_tile(true))
	bottom.add_child(WF.make_label("×1", 14, WF.MUTED))
	body.add_child(bottom)
	body.add_child(WF.wf_btn("Cancel", false, true))
	return p

static func wf_victory() -> Control:
	var p := WF.Phone.new()
	var body := p.padded_body(Vector4(24, 32, 24, 24), 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_center_label("🎉", 48, WF.TEXT, true))
	body.add_child(_center_label("Victory!", 32, WF.SUCCESS, true))
	body.add_child(_center_label("You defeated Goblin", 18, WF.MUTED))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 24)
	stats.add_child(WF.score_box("Damage dealt", "240", "", WF.SUCCESS))
	stats.add_child(WF.score_box("Words used", "8", "", WF.ACCENT))
	body.add_child(stats)
	# Battle summary card
	var card := WF.card(WF.PAPER, WF.BORDER_LITE, 16, 16, 2)
	var sbox := VBoxContainer.new()
	sbox.add_theme_constant_override("separation", 6)
	sbox.add_child(WF.make_label("Battle Summary", 18, WF.TEXT, true))
	for row_data in [
		["Longest word","CHICKEN (7)"],
		["Topic matches","3 words"],
		["Rainbows used","1"],
		["Score earned","+450 pts"],
	]:
		sbox.add_child(_kv_row(row_data[0], row_data[1], row_data[0] == "Score earned"))
	card.add_child(sbox)
	body.add_child(card)
	body.add_child(WF.wf_btn("Next Battle →", true))
	body.add_child(WF.wf_btn("Back to Map", false, true))
	return p

static func wf_defeat() -> Control:
	var p := WF.Phone.new()
	var body := p.padded_body(Vector4(24, 32, 24, 24), 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_center_label("💔", 48, WF.TEXT, true))
	body.add_child(_center_label("Defeated!", 32, WF.DANGER, true))
	body.add_child(_center_label("Dragon was too strong this time", 18, WF.MUTED))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 24)
	stats.add_child(WF.score_box("Your HP left", "0", "", WF.DANGER))
	stats.add_child(WF.score_box("Enemy HP left", "15", "", WF.MUTED))
	body.add_child(stats)
	var tip := WF.card(WF.PAPER, WF.BORDER_LITE, 16, 16, 2)
	var tip_lbl := WF.make_label("Tip: Try using longer words for more damage, and match the topic for ×2 bonus!", 16, WF.MUTED)
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_child(tip_lbl)
	body.add_child(tip)
	body.add_child(WF.wf_btn("Try Again", true))
	body.add_child(WF.wf_btn("Back to Map", false, true))
	return p

# ─────────── WORD MATCH ───────────

static func wm_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Match", true, "Intermediate"))
	var body := p.padded_body(Vector4(16, 16, 16, 16), 12)
	var top := HBoxContainer.new()
	top.add_child(WF.timer_badge("1:42"))
	top.add_child(_h_spacer_expand())
	top.add_child(WF.score_box("Score", "320"))
	body.add_child(top)
	# Found words card
	var found := WF.card(WF.PAPER, WF.BORDER_LITE, 12, 12, 2)
	var found_box := VBoxContainer.new()
	found_box.add_child(WF.make_label("Found words", 14, WF.MUTED))
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 6)
	for w in ["BIG","RIG","BIT","GRIT","BRIT"]:
		pills.add_child(WF.pill(w, WF.SUCCESS, WF.SUCCESS_BG))
	pills.add_child(WF.pill("???", WF.BORDER_LITE, Color("#f5f5f3")))
	pills.add_child(WF.pill("???", WF.BORDER_LITE, Color("#f5f5f3")))
	pills.add_child(WF.pill("????", WF.BORDER_LITE, Color("#f5f5f3")))
	found_box.add_child(pills)
	found.add_child(found_box)
	body.add_child(found)
	# Current word
	var current := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 10, 2)
	var cw := WF.make_label("BRI", 24, WF.ACCENT, true)
	cw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current.add_child(cw)
	body.add_child(current)
	# Circle of letters
	body.add_child(_letter_circle(["B","R","I","G","H","T"], [0, 4, 2]))
	body.add_child(WF.note("Drag across letters to form words — lift to submit"))
	return p

static func wm_results() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Match — Results", true))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 16)
	body.add_child(_center_label("Time's Up!", 32, WF.TEXT, true))
	body.add_child(_center_label("Great job finding words", 18, WF.MUTED))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 20)
	stats.add_child(WF.score_box("Words Found", "8", "", WF.SUCCESS))
	stats.add_child(WF.score_box("Total Score", "520", "", WF.ACCENT))
	body.add_child(stats)
	# All possible
	var card := WF.card(WF.PAPER, WF.BORDER_LITE, 14, 14, 2)
	var box := VBoxContainer.new()
	box.add_child(WF.make_label("All possible words", 18, WF.TEXT, true))
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 6)
	var words := ["BIG","RIG","BIT","GRIT","BRIT","RIGHT","BRIGHT","BRIG","GIRTH","BIRTH"]
	for i in words.size():
		if i < 5:
			pills.add_child(WF.pill(words[i] + " ✓", WF.SUCCESS, WF.SUCCESS_BG))
		else:
			pills.add_child(WF.pill(words[i] + " ✗", WF.DANGER, WF.DANGER_BG))
	box.add_child(pills)
	box.add_child(WF.make_label("You found 5 of 10 words", 14, WF.MUTED))
	card.add_child(box)
	body.add_child(card)
	body.add_child(WF.wf_btn("Play Again", true))
	body.add_child(WF.wf_btn("Back to Map", false, true))
	return p

# ─────────── WORD FOUND ───────────

static func wfnd_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Found", true, "Intermediate"))
	var body := p.padded_body(Vector4(16, 16, 16, 16), 12)
	var top := HBoxContainer.new()
	top.add_child(WF.wave_tag(3))
	top.add_child(_h_spacer_expand())
	top.add_child(WF.score_box("Score", "680"))
	body.add_child(top)
	# Target
	var tcard := WF.card(WF.PURPLE_BG, WF.PURPLE, 12, 12, 2)
	var tbox := VBoxContainer.new()
	tbox.add_child(WF.make_label("Target: find these words", 14, WF.PURPLE, true))
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 6)
	pills.add_child(WF.pill("PAINT ✓", WF.SUCCESS, WF.SUCCESS_BG))
	pills.add_child(WF.pill("_ _ _ _ (4 letters)", WF.TEXT, WF.PAPER))
	pills.add_child(WF.pill("_ _ _ _ _ (5 letters)", WF.TEXT, WF.PAPER))
	tbox.add_child(pills)
	tcard.add_child(tbox)
	body.add_child(tcard)
	# Row 2
	body.add_child(WF.make_label("Your word ↓", 14, WF.MUTED))
	var row2 := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 12, 2)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 6)
	for c in ["P","A","I","N","T"]:
		r2.add_child(WF.tile(c, true, false, false, 40))
	r2.add_child(WF.make_label("tap to undo", 14, WF.MUTED))
	row2.add_child(r2)
	body.add_child(row2)
	# Row 1
	body.add_child(WF.make_label("Available letters ↓ tap to use", 14, WF.MUTED))
	var row1 := WF.card(WF.PAPER, WF.BORDER_LITE, 8, 12, 2)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 6)
	r1.alignment = BoxContainer.ALIGNMENT_CENTER
	var letters := ["P","A","I","N","T","E","R","S","A","L","E"]
	for i in letters.size():
		r1.add_child(WF.tile(letters[i], false, false, i < 5, 40))
	row1.add_child(r1)
	body.add_child(row1)
	# Bonus
	var bonus := WF.card(Color("#f5f5f3"), Color(0,0,0,0), 10, 10, 0)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 6)
	brow.add_child(WF.make_label("Bonus words:", 14, WF.MUTED))
	brow.add_child(WF.pill("PAN", WF.SUCCESS, WF.SUCCESS_BG))
	brow.add_child(WF.pill("TIN", WF.SUCCESS, WF.SUCCESS_BG))
	bonus.add_child(brow)
	body.add_child(bonus)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var c1 := WF.wf_btn("Clear", false, true); c1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(c1)
	var c2 := WF.wf_btn("Submit Word", true); c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(c2)
	body.add_child(actions)
	return p

static func wfnd_wave() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Found", true))
	var body := p.padded_body(Vector4(24, 32, 24, 24), 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_center_label("🌊", 40, WF.TEXT, true))
	body.add_child(_center_label("Wave 3 Complete!", 28, WF.PURPLE, true))
	body.add_child(_center_label("All target words found", 18, WF.MUTED))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 16)
	stats.add_child(WF.score_box("Target", "3/3", "", WF.SUCCESS))
	stats.add_child(WF.score_box("Bonus", "+2", "", WF.WARN))
	stats.add_child(WF.score_box("Score", "+280", "", WF.ACCENT))
	body.add_child(stats)
	var next_card := WF.card(WF.PAPER, WF.BORDER_LITE, 12, 12, 2)
	var nb := VBoxContainer.new()
	var n1 := WF.make_label("Next wave: 3× 5-letter + 1× 6-letter words", 16, WF.MUTED)
	n1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb.add_child(n1)
	var n2 := WF.make_label("Difficulty increases!", 14, WF.WARN)
	n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb.add_child(n2)
	next_card.add_child(nb)
	body.add_child(next_card)
	body.add_child(WF.wf_btn("Start Wave 4 →", true))
	return p

static func wfnd_over() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Found", true))
	var body := p.padded_body(Vector4(24, 32, 24, 24), 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_center_label("😓", 40, WF.TEXT, true))
	body.add_child(_center_label("Game Over", 28, WF.TEXT, true))
	body.add_child(_center_label("Couldn't complete Wave 8", 18, WF.MUTED))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 16)
	stats.add_child(WF.score_box("Waves", "7", "", WF.PURPLE))
	stats.add_child(WF.score_box("Words", "24", "", WF.SUCCESS))
	stats.add_child(WF.score_box("Total", "1,840", "", WF.ACCENT))
	body.add_child(stats)
	var warn_card := WF.card(WF.WARN_BG, WF.WARN, 12, 12, 2)
	var wlbl := WF.make_label("⚠ No valid words possible with remaining letters", 15, WF.WARN)
	wlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_card.add_child(wlbl)
	body.add_child(warn_card)
	body.add_child(WF.wf_btn("Play Again", true))
	body.add_child(WF.wf_btn("Back to Map", false, true))
	return p

# ─────────── STORY TELL ───────────

static func st_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Story Tell", true, "Intermediate"))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 16)
	body.add_child(WF.pill("📖 Story #4", WF.PURPLE, WF.PURPLE_BG))
	# Story card
	var card := WF.card(WF.PAPER, WF.BORDER_LITE, 16, 14, 2)
	var story := RichTextLabel.new()
	story.bbcode_enabled = true
	story.fit_content = true
	story.text = "Last summer, Maria went to the beach with her family. She [color=#5B8DEF][b]loved swimming[/b][/color] in the warm ocean waves. Her brother [color=#999][i]tap to write...[/i][/color] while their parents relaxed under a big umbrella. At the end of the day, everyone felt [color=#999][i]tap to write...[/i][/color]."
	story.add_theme_font_override("normal_font", WF.font_regular())
	story.add_theme_font_size_override("normal_font_size", 20)
	story.add_theme_color_override("default_color", WF.TEXT)
	card.add_child(story)
	body.add_child(card)
	body.add_child(WF.note("Fill in each blank to complete the story. Longer, grammatically correct answers score higher!"))
	body.add_child(_center_label("1 of 3 blanks filled", 14, WF.MUTED))
	body.add_child(WF.hp_bar(1, 3, WF.ACCENT, "", false, 8))
	body.add_child(WF.wf_btn("Submit Story", true, false, false, true))
	return p

static func st_results() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Story Tell — Results", true))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 14)
	body.add_child(_center_label("Story Scored!", 28, WF.TEXT, true))
	body.add_child(WF.score_box("Total Score", "85/100", "", WF.ACCENT))
	var blanks := [
		{"num":1,"yours":"loved swimming","score":"28/30","verdict":"Excellent grammar!","ok":true},
		{"num":2,"yours":"was build sandcastles","score":"18/35","verdict":"Check verb form: \"was building\"","ok":false},
		{"num":3,"yours":"happy and tired","score":"32/35","verdict":"Natural and accurate!","ok":true},
	]
	for b in blanks:
		var card := WF.card(WF.PAPER, WF.BORDER_LITE, 12, 12, 2)
		var box := VBoxContainer.new()
		var row := HBoxContainer.new()
		row.add_child(WF.make_label("Blank %d" % b.num, 16, WF.TEXT, true))
		row.add_child(_h_spacer_expand())
		row.add_child(WF.pill(b.score, WF.SUCCESS if b.ok else WF.WARN, WF.SUCCESS_BG if b.ok else WF.WARN_BG))
		box.add_child(row)
		box.add_child(WF.make_label("You wrote: \"%s\"" % b.yours, 16, WF.TEXT))
		box.add_child(WF.make_label(b.verdict, 14, WF.SUCCESS if b.ok else WF.WARN))
		card.add_child(box)
		body.add_child(card)
	# Sample answers
	var sample := WF.card(WF.ACCENT_BG, WF.ACCENT, 12, 12, 2)
	var sb := VBoxContainer.new()
	var srow := HBoxContainer.new()
	srow.add_child(WF.make_label("Sample Answers", 16, WF.ACCENT, true))
	srow.add_child(_h_spacer_expand())
	srow.add_child(WF.pill("Intermediate", Color.WHITE, WF.ACCENT))
	srow.add_child(WF.pill("Advanced", WF.MUTED, WF.PAPER))
	sb.add_child(srow)
	var stxt := WF.make_label("\"...She enjoyed swimming...Her brother was building a sandcastle...everyone felt happy but exhausted.\"", 15, WF.TEXT)
	stxt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sb.add_child(stxt)
	sample.add_child(sb)
	body.add_child(sample)
	body.add_child(WF.wf_btn("Next Story →", true))
	return p

# ─────────── WORD TYPE ───────────

static func wt_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Type", true, "Intermediate"))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 16)
	var word_card := WF.card(WF.PAPER, WF.BORDER, 20, 16, 2)
	var wb := VBoxContainer.new()
	wb.alignment = BoxContainer.ALIGNMENT_CENTER
	var hint := WF.make_label("Transform this word", 14, WF.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb.add_child(hint)
	var w := WF.make_label("Careful", 38, WF.TEXT, true)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb.add_child(w)
	var pos_holder := CenterContainer.new()
	pos_holder.add_child(WF.pill("adjective", WF.ACCENT, WF.ACCENT_BG))
	wb.add_child(pos_holder)
	word_card.add_child(wb)
	body.add_child(word_card)
	body.add_child(_center_label("This word has 6 forms — fill in what you know!", 18, WF.PURPLE, true))
	body.add_child(WF.wf_input("Type a word form...", "carefully"))
	body.add_child(WF.wf_input("Type a word form...", "careless"))
	body.add_child(WF.wf_input("Type a word form..."))
	body.add_child(WF.wf_input("Type a word form..."))
	body.add_child(WF.note("You don't need to fill all boxes — partial credit is given!"))
	body.add_child(WF.wf_btn("Submit", true))
	return p

static func wt_results() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Word Type — Results", true))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 14)
	body.add_child(_center_label("Results", 28, WF.TEXT, true))
	body.add_child(_center_label("careful — adjective", 18, WF.MUTED))
	body.add_child(WF.score_box("Score", "2/6", "forms found", WF.ACCENT))
	var card := WF.card(WF.PAPER, WF.BORDER_LITE, 14, 14, 2)
	var cb := VBoxContainer.new()
	cb.add_child(WF.make_label("All Word Forms", 18, WF.TEXT, true))
	var forms := [
		{"form":"carefully","type":"adverb","yours":true,"ex":"\"She carefully opened the box.\""},
		{"form":"careless","type":"adjective","yours":true,"ex":"\"That was a careless mistake.\""},
		{"form":"carelessly","type":"adverb","yours":false,"ex":"\"He carelessly dropped the vase.\""},
		{"form":"carefulness","type":"noun","yours":false,"ex":"\"Her carefulness saved the project.\""},
		{"form":"carelessness","type":"noun","yours":false,"ex":"\"Carelessness leads to errors.\""},
		{"form":"care","type":"noun/verb","yours":false,"ex":"\"I care about the result.\""},
	]
	for i in forms.size():
		var f = forms[i]
		var row := HBoxContainer.new()
		var name_l := WF.make_label("%s (%s)" % [f.form, f.type], 17, WF.TEXT, true)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		row.add_child(WF.pill("✓ Found" if f.yours else "Missed",
			WF.SUCCESS if f.yours else WF.DANGER,
			WF.SUCCESS_BG if f.yours else WF.DANGER_BG))
		cb.add_child(row)
		var ex := WF.make_label(f.ex, 13, WF.MUTED)
		cb.add_child(ex)
	card.add_child(cb)
	body.add_child(card)
	body.add_child(WF.wf_btn("Next Word →", true))
	return p

# ─────────── DESCRIBE PICTURE ───────────

static func dp_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Describe Picture", true, "Intermediate"))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 14)
	body.add_child(WF.img_holder("illustrated character: girl in park with dog", 160))
	body.add_child(WF.make_label("Complete each sentence:", 18, WF.TEXT, true))
	for sentence in [
		["She is","sitting on a bench"],
		["She has",""],
		["She wears",""],
		["It seems like",""],
	]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var stem := WF.make_label(sentence[0], 18, WF.TEXT, true)
		stem.custom_minimum_size = Vector2(90, 0)
		r.add_child(stem)
		var inp := WF.wf_input("...", sentence[1])
		inp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(inp)
		body.add_child(r)
	body.add_child(WF.note("Longer, natural sentences score higher"))
	body.add_child(WF.wf_btn("Submit All", true))
	return p

static func dp_results() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Describe Picture — Results", true))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 14)
	body.add_child(_center_label("Scored!", 28, WF.TEXT, true))
	body.add_child(WF.score_box("Total", "72/100", "", WF.ACCENT))
	var rows := [
		{"stem":"She is","yours":"sitting on a bench","score":"22/25","ok":true,"rec":"sitting on a park bench and reading a book"},
		{"stem":"She has","yours":"long hair","score":"15/25","ok":true,"rec":"long brown hair tied in a ponytail"},
		{"stem":"She wears","yours":"a red dress","score":"20/25","ok":true,"rec":"a red dress with white polka dots"},
		{"stem":"It seems like","yours":"she is happy","score":"15/25","ok":false,"rec":"she is enjoying a peaceful afternoon in the park"},
	]
	for r in rows:
		var card := WF.card(WF.PAPER, WF.BORDER_LITE, 10, 10, 2)
		var b := VBoxContainer.new()
		var top := HBoxContainer.new()
		top.add_child(WF.make_label(r.stem + "...", 16, WF.TEXT, true))
		top.add_child(_h_spacer_expand())
		top.add_child(WF.pill(r.score, WF.SUCCESS if r.ok else WF.WARN, WF.SUCCESS_BG if r.ok else WF.WARN_BG))
		b.add_child(top)
		b.add_child(WF.make_label("You: \"%s\"" % r.yours, 15, WF.TEXT))
		b.add_child(WF.make_label("💡 " + r.rec, 14, WF.ACCENT))
		card.add_child(b)
		body.add_child(card)
	body.add_child(WF.wf_btn("Next Picture →", true))
	return p

# ─────────── LISTEN & DICTATE ───────────

static func ld_game() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Listen & Dictate", true, "Advanced"))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 16)
	body.add_child(_center_label("Listen to the word and type it", 18, WF.MUTED))
	body.add_child(WF.audio_ctrl(true))
	body.add_child(_center_label("Replays used: 1 (−10 pts each)", 14, WF.WARN))
	# Letter boxes
	var letters := ["B","E","A","U","T","I","F","U","L"]
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 8)
	for i in letters.size():
		grid.add_child(_letter_box(letters[i] if i < 5 else "", i < 5))
	body.add_child(grid)
	body.add_child(_center_label("9 letters", 14, WF.MUTED))
	# Keyboard hint
	var kb_card := WF.card(Color("#f0f0ee"), Color(0,0,0,0), 12, 12, 0)
	var kb_box := VBoxContainer.new()
	kb_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for k in ["Q","W","E","R","T","Y","U","I","O","P"]:
		row.add_child(_kb_key(k))
	kb_box.add_child(row)
	var dots := WF.make_label("... keyboard", 12, WF.MUTED)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_box.add_child(dots)
	kb_card.add_child(kb_box)
	body.add_child(kb_card)
	body.add_child(WF.wf_btn("Submit (fill all boxes)", true, false, false, true))
	return p

static func ld_results() -> Control:
	var p := WF.Phone.new()
	p.set_header(WF.app_head("Listen & Dictate — Results", true))
	var body := p.padded_body(Vector4(20, 20, 20, 20), 16)
	body.add_child(_center_label("Correct! ✓", 28, WF.SUCCESS, true))
	var letter_row := HBoxContainer.new()
	letter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	letter_row.add_theme_constant_override("separation", 6)
	for l in ["B","E","A","U","T","I","F","U","L"]:
		var b := _letter_box(l, true, true)
		letter_row.add_child(b)
	body.add_child(letter_row)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 16)
	stats.add_child(WF.score_box("Accuracy", "100%", "", WF.SUCCESS))
	stats.add_child(WF.score_box("Replays", "1", "−10 pts", WF.WARN))
	stats.add_child(WF.score_box("Score", "80", "", WF.ACCENT))
	body.add_child(stats)
	var sentence_card := WF.card(WF.ACCENT_BG, WF.ACCENT, 16, 14, 2)
	var sb := VBoxContainer.new()
	sb.add_child(WF.make_label("Example sentence", 16, WF.ACCENT, true))
	var s := WF.make_label("\"The sunset was beautiful — a mix of orange and pink filled the sky.\"", 18, WF.TEXT)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sb.add_child(s)
	sentence_card.add_child(sb)
	body.add_child(sentence_card)
	body.add_child(WF.wf_btn("Next Word →", true))
	body.add_child(WF.wf_btn("Back to Map", false, true))
	return p

# ─────────── helpers ───────────

static func _center_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := WF.make_label(text, size, color, bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func _v_spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

static func _h_spacer_expand() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

static func _avatar_tile(emoji: String, active: bool) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.ACCENT_BG if active else WF.PAPER
	sb.set_border_width_all(2 if active else 2)
	sb.border_color = WF.ACCENT if active else WF.BORDER_LITE
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(60, 60)
	var c := CenterContainer.new()
	panel.add_child(c)
	c.add_child(WF.make_label(emoji, 28, WF.TEXT))
	return panel

static func _mode_card(title: String, sub: String, selected: bool) -> Control:
	var card := WF.card(WF.ACCENT_BG if selected else WF.PAPER, WF.ACCENT if selected else WF.BORDER_LITE, 20, 16, 2 if selected else 2)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(_radio(selected))
	top.add_child(WF.make_label(title, 24, WF.TEXT, true))
	box.add_child(top)
	var sub_l := WF.make_label(sub, 16, WF.MUTED)
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub_l)
	card.add_child(box)
	return card

static func _radio(filled: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.ACCENT if filled else Color(0,0,0,0)
	sb.set_border_width_all(2)
	sb.border_color = WF.ACCENT if filled else WF.BORDER_LITE
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(20, 20)
	return p

static func _path_node(n: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon := _circle_icon(n.get("icon","?"), n.get("active", false), n.get("done", false))
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_color := WF.ACCENT if n.get("active", false) else (WF.SUCCESS if n.get("done", false) else WF.MUTED)
	var name_l := WF.make_label(n.name, 20, name_color, n.get("active", false))
	info.add_child(name_l)
	if n.get("active", false):
		info.add_child(WF.pill("Play now!", WF.ACCENT, WF.ACCENT_BG))
	elif n.get("done", false):
		info.add_child(WF.make_label("★ 450 pts", 14, WF.SUCCESS))
	row.add_child(info)
	return row

static func _winding_node(n: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	col.custom_minimum_size = Vector2(96, 0)
	col.add_child(_circle_icon(n.get("icon","?"), n.get("active", false), n.get("done", false), 56))
	var name_color := WF.ACCENT if n.get("active", false) else (WF.SUCCESS if n.get("done", false) else WF.MUTED)
	var name_l := WF.make_label(n.name, 15, name_color, true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_l)
	if n.get("active", false):
		col.add_child(WF.pill("Play!", Color.WHITE, WF.ACCENT))
	return col

static func _circle_icon(icon_text: String, active: bool, done: bool, sz: int = 48) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.ACCENT_BG if active else (WF.SUCCESS_BG if done else WF.PAPER)
	sb.set_border_width_all(3 if active else 2)
	sb.border_color = WF.ACCENT if active else (WF.SUCCESS if done else WF.BORDER_LITE)
	sb.set_corner_radius_all(sz / 2)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(sz, sz)
	var c := CenterContainer.new()
	p.add_child(c)
	var glyph := WF.make_label("✓" if done else icon_text, 22 if sz <= 50 else 26, WF.SUCCESS if done else WF.TEXT, true)
	c.add_child(glyph)
	return p

static func _game_card(g: Dictionary) -> Control:
	var card := WF.card(WF.ACCENT_BG if g.get("active", false) else WF.PAPER, WF.ACCENT if g.get("active", false) else WF.BORDER_LITE, 14, 16, 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	# Icon box
	var icon := _circle_icon(g.get("icon","?"), g.get("active", false), g.get("done", false), 50)
	row.add_child(icon)
	# Text col
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nc := WF.ACCENT if g.get("active", false) else (WF.SUCCESS if g.get("done", false) else WF.MUTED)
	info.add_child(WF.make_label(g.name, 20, nc, true))
	info.add_child(WF.make_label(g.desc, 14, WF.MUTED))
	if g.get("done", false):
		info.add_child(WF.make_label("★ %d pts" % g.score, 13, WF.SUCCESS))
	row.add_child(info)
	# Right side
	if g.get("active", false):
		row.add_child(WF.wf_btn("Play", true, false, true, false, false))
	elif not g.get("done", false):
		row.add_child(WF.make_label("🔒", 22, WF.BORDER_LITE))
	card.add_child(row)
	return card

static func _hp_row(avatar_node: Control, bar_node: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(avatar_node)
	bar_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_node)
	return row

static func _mini_rainbow_tile(big: bool = false) -> Control:
	var sz := 28 if not big else 30
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(sz, sz)
	holder.add_child(WF._TileCanvas.new("★", false, true, false, sz))
	return holder

static func _empty_slot(bg: Color = Color("#eee"), border: Color = WF.BORDER_LITE) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(28, 28)
	var dot := WF.make_label("·", 14, WF.MUTED)
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(dot)
	return p

static func _kv_row(k: String, v: String, accent: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var kl := WF.make_label(k, 16, WF.TEXT)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kl)
	var vl := WF.make_label(v, 16, WF.ACCENT if accent else WF.TEXT, true)
	row.add_child(vl)
	return row

static func _letter_circle(letters: Array, selected_indices: Array) -> Control:
	var size_px := 200
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size_px, size_px)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(_CircleCanvas.new(letters, selected_indices, size_px))
	return holder

class _CircleCanvas extends Control:
	var letters: Array
	var selected_indices: Array
	var size_px: int
	func _init(l: Array, s: Array, sz: int) -> void:
		letters = l; selected_indices = s; size_px = sz
		custom_minimum_size = Vector2(sz, sz)
	func _draw() -> void:
		var center := Vector2(size_px, size_px) * 0.5
		var r := 80.0
		var step := TAU / letters.size()
		# connection lines between selected indices in chain order
		for i in range(selected_indices.size() - 1):
			var a1: float = float(selected_indices[i]) * step - PI * 0.5
			var a2: float = float(selected_indices[i + 1]) * step - PI * 0.5
			var p1: Vector2 = center + Vector2(cos(a1), sin(a1)) * r
			var p2: Vector2 = center + Vector2(cos(a2), sin(a2)) * r
			draw_line(p1, p2, WF.ACCENT, 3)
		# letter circles
		for i in letters.size():
			var angle := i * step - PI * 0.5
			var pos := center + Vector2(cos(angle), sin(angle)) * r
			var sel := i in selected_indices
			# circle
			draw_circle(pos, 24, WF.ACCENT_BG if sel else WF.PAPER)
			draw_arc(pos, 24, 0, TAU, 48, WF.ACCENT if sel else WF.BORDER, 3 if sel else 2, true)
			var f := WF.font_bold()
			var fs := 22
			var ts := f.get_string_size(letters[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(f, pos - ts * 0.5 + Vector2(0, fs * 0.36),
				letters[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs,
				WF.ACCENT if sel else WF.TEXT)

static func _dark_tile(letter: String, selected: bool, rainbow: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.DARK_CELL
	sb.set_border_width_all(2)
	sb.border_color = Color("#445")
	sb.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(48, 48)
	var c := CenterContainer.new()
	p.add_child(c)
	if rainbow:
		# overlay rainbow gradient via canvas-like child
		var rb := WF._TileCanvas.new(letter, false, true, false, 44)
		c.add_child(rb)
	else:
		var lbl := WF.make_label(letter, 20, WF.ACCENT if selected else Color("#bbb"), true)
		c.add_child(lbl)
	return p

static func _letter_box(letter: String, filled: bool, success: bool = false) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.SUCCESS_BG if success else (WF.ACCENT_BG if filled else WF.PAPER)
	sb.set_border_width_all(2 if filled or success else 1)
	sb.border_color = WF.SUCCESS if success else (WF.ACCENT if filled else WF.BORDER_LITE)
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(32, 42)
	var c := CenterContainer.new()
	p.add_child(c)
	c.add_child(WF.make_label(letter, 20, WF.SUCCESS if success else (WF.ACCENT if filled else WF.MUTED), true))
	return p

static func _kb_key(letter: String) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.PAPER
	sb.set_border_width_all(1)
	sb.border_color = WF.BORDER_LITE
	sb.set_corner_radius_all(5)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(26, 32)
	var c := CenterContainer.new()
	p.add_child(c)
	var l := Label.new()
	l.text = letter
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", WF.TEXT)
	c.add_child(l)
	return p
