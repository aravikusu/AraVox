## just don't look at this file please

@tool
class_name AraVoxHighlighter
extends CodeHighlighter

const COLOR_COMMENT: Color = Color(0.384, 0.447, 0.643)
const COLOR_SPEAKER: Color = Color(0.314, 0.980, 0.482)
const COLOR_MUSTACHE: Color = Color(1.0, 0.722, 0.424)
const COLOR_KEYWORD: Color = Color(0.741, 0.576, 0.976)
const COLOR_CLOSER: Color = Color(1.0, 0.475, 0.776)
const COLOR_DATA: Color = Color(0.545, 0.914, 0.992)
const COLOR_SHORTHAND: Color = Color(0.945, 0.980, 0.549)
const COLOR_DEFAULT: Color = Color(0.75, 0.75, 0.78)

const KEYWORDS: Array[String] = ["#if", "#else", "#choice", "#action", "#rand", "#pl", "#branch"]
const CLOSERS: Array[String] = ["/if", "/choice", "/branch", "/else"]

func _get_line_syntax_highlighting(line_index: int) -> Dictionary:
	## this stuff is absolute lunacy, who decided to torture me in this way?
	var map: Dictionary = {}
	var line: String = get_text_edit().get_line(line_index)

	if line.strip_edges().begins_with("#"):
		map[0] = {color = COLOR_COMMENT}
		return map

	map[0] = {color = COLOR_DEFAULT}

	var i: int = 0
	while i < line.length():
		# color for speaker
		if line[i] == "[":
			map[i] = {color = COLOR_SPEAKER}
			var close: int = line.find("]", i + 1)
			if close != -1:
				map[close + 1] = {color = COLOR_DEFAULT}
				i = close + 1
			else:
				i += 1
		# mustache babyyy
		elif i < line.length() - 1 && line[i] == "{" && line[i + 1] == "{":
			map[i] = {color = COLOR_MUSTACHE}
			i += 2
			var content_start: int = i

			# time for madness, what are we doing now?
			var token: String = ""
			var j: int = i
			while j < line.length() && line[j] != " " && !(line[j] == "}" && j + 1 < line.length() && line[j + 1] == "}"):
				token += line[j]
				j += 1

			if token in CLOSERS:
				map[content_start] = {color = COLOR_CLOSER}
				i = j
			elif token in KEYWORDS:
				map[content_start] = {color = COLOR_KEYWORD}
				i = j
				# Further checks: do we break out, do normal color, or data, or...
				while i < line.length() - 1:
					if line[i] == "}" && line[i + 1] == "}":
						break
					if line[i] == "$":
						map[i] = {color = COLOR_DATA}
						while i < line.length() && line[i] != "," && line[i] != " " && !(line[i] == "}" && i + 1 < line.length() && line[i + 1] == "}"):
							i += 1
						map[i] = {color = COLOR_DEFAULT}
					else:
						i += 1
			# "Wow, I hate this. It is revolting!" "More?" "Please."
			elif token.begins_with("$"):
				map[content_start] = {color = COLOR_DATA}
				i = j
			# Shorthand! At least you and data are simple
			elif token.begins_with("%"):
				map[content_start] = {color = COLOR_SHORTHAND}
				i = j
			else:
				i = j

			# Close the mustache
			var close_idx: int = line.find("}}", i)
			if close_idx != -1:
				map[close_idx] = {color = COLOR_MUSTACHE}
				map[close_idx + 2] = {color = COLOR_DEFAULT}
				i = close_idx + 2
			else:
				break
		else:
			i += 1

	return map
