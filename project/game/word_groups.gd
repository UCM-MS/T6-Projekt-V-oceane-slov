extends RefCounted

const WORDS := {
	"b": ["b_k", "býk", "ý"],
	"m": ["m_š", "myš", "y"],
	"p": ["p_cha", "pýcha", "ý"],
	"r": ["r_chly", "rýchly", "ý"],
	"s": ["s_r", "syr", "y"],
	"v": ["v_r", "výr", "ý"],
	"z": ["jaz_k", "jazyk", "y"],
}

static var selected: Array[String] = ["b", "m", "p", "r", "s", "v", "z"]
