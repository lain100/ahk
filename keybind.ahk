#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange Using_MPC_BE

LastKey := ""
layer(key := "", key2 := "", HotKey := GetHotKey()) {
	global LastKey := HotKey = "vk1c" || HotKey = "vk1d" ? HotKey : ""
	key ? Send("{Blind}{" key " Down}") : ""
	KeyWait(HotKey)
	key ? Send("{Blind}{" key " Up}") : ""	
	HotKey := LastKey = HotKey ? "" : HotKey
	A_PriorKey = HotKey && key2 ? Send("{Blind}" key2) : ""
}
Prim(str, cond := "P") {
	for key in ["Ctrl", "Shift"]
		if GetKeyState(key, cond)
			str := "{" key " Up}" str "{" key " Down}"
	return str
}
Toggle(key := "", key2 := "", trg := "", cond := "P") {
	Send("{Blind}" WithKey(key, key2, trg, cond))
	if key2 && !(trg || KeyWait(GetHotKey(), "T0.2"))
	  Send("{Blind}" key2) || KeyWait(GetHotKey())
}
GetHotKey(Trg := A_ThisHotKey, HotKey := LTrim(trg, "~+*``")) =>
	InStr(HotKey, " up") ? SubStr(HotKey, 1, -3) : HotKey

Arpeggio(key := "", key2 := "", trg := GetHotKey()) =>
	Send("{Blind}" (trg = GetHotKey(A_PriorHotKey) ? key2 : key))

WithKey(key := "", key2 := "", trg := "", cond := "P") =>
	trg && GetKeyState(trg, cond) ? key2 : key

Using_MPC_BE(*) => InStr(A_Clipboard, "youtu") &&
	Run("C:\Program Files\MPC-BE\mpc-be64.exe " A_Clipboard)

Search(url) => Send("^{c}") || Sleep(100) || Run(url . A_Clipboard)

Notice(str, delay := 1000) => ToolTip(str) && SetTimer(ToolTip, -delay)

*-::
*^::
*\::
*t::
*y::
*@::
*[::
*]::
*b::
*Esc::
*Tab::
*vkE2::
*LShift::
*LAlt::
*RAlt::
*LWin::return

w::l
e::u
r::f

a::e
s::i
d::a
f::o
g::-

z::x
x::c
c::v
v::,

u::r
i::y
o::h
p::w

h::p
j::t
k::n
*l::Toggle("k", "n", "k")
`;::s
vkBA::j

n::b
m::d
,::m
.::g
/::z

*vk1d::Layer(, "{Enter}")
*Space::Layer("F16", "{Space}")
*vk1c::Layer(, "{BackSpace}")
*Delete::Layer("Shift")
~RButton::KeyWait(GetHotKey(), "T0.08") ? Send("o") : ""

#HotIf GetKeyState("LShift", "P")
u::Search("https://www.google.com/search?q=")
i::Search("https://www.oxfordlearnersdictionaries.com/definition/english/")
o::Search("https://www.etymonline.com/search?q=")
p::Search("https://translate.google.com/?sl=auto&tl=ja&text=")

h::Run("https://x.com/husino93/with_replies")
j::Run("https://x.com/489wiki")
k::Run("https://bsky.app/profile/489wiki.bsky.social")
l::Run("https://typingch.c4on.jp/game/index.html")
`;::Run("https://keyx0.net/easy/")
vkBA::Run("https://o24.works/atc/")

n::Run("https://drive.google.com/drive/u/0/my-drive")
m::Run("https://www.nct9.ne.jp/m_hiroi/clisp/index.html")
,::Run("https://qiita.com/tomoswifty/items/be3ff39ab3361a8e9c47")

#HotIf GetKeyState("vk1c", "P")
q::@
*w::Arpeggio("[", "{Left}[", "r")
*e::Arpeggio('"', '"{Left}')
*r::Arpeggio("]", "]{Left}", "w")

a::#
*s::GetKeyState("F16", "L") ? Layer("LWin") : Arpeggio("(", "{Left}(", "f")
*d::GetKeyState("F16", "L") ? Layer("LAlt") : Arpeggio("'", "'{Left}")
*f::GetKeyState("F16", "L") ? Layer("LShift") : Arpeggio(")", "){Left}", "s")
g::&

*z::Arpeggio("{{}", "{Left}{{}", "c")
*x::Arpeggio("``", "``{Left}")
*c::Arpeggio("{}}", "{}}{Left}", "z")
v::|

u::Esc
i::Tab
*o::Arpeggio(GetKeyState("F16", "L") ? "{vkf2}" : "{vkf2}{vkf3}", "{Esc}")
p::vk5d

h::Left
j::Down
k::Up
l::Right
`;::!Tab
vkBA::!F4

n::Send(GetKeyState("F16", "L") ? "{Volume_Down}" : "{Volume_Up}")
*m::Send(GetKeyState("F16", "L") ? "{Pgdn}" : "{Home}")
*,::Send(GetKeyState("F16", "L") ? "{Pgup}" : "{End}")
.::Volume_mute
/::Browser_Home

#HotIf GetKeyState("Space", "P")
*q::GetKeyState("Delete", "P") ? Layer(, Prim("{F11}", "L")) : Toggle("~")
*w::GetKeyState("Delete", "P") ?
	Toggle(Prim("{F1}", "L"), Prim("{F12}", "L"), "q") : Toggle("1")
*e::Toggle("2", Prim("{F2}", "L"), "Delete", "P")
*r::Toggle("3", Prim("{F3}", "L"), "Delete", "P")

*a::Toggle("0", Prim("{F10}", "L"), "Delete", "P")
*s::Toggle("4", Prim("{F4}", "L"), "Delete", "P")
*d::Toggle("5", Prim("{F5}", "L"), "Delete", "P")
*f::Toggle("6", Prim("{F6}", "L"), "Delete", "P")
g::$

*z::Toggle("7", Prim("{F7}", "L"), "Delete", "P")
*x::Toggle("8", Prim("{F8}", "L"), "Delete", "P")
*c::Toggle("9", Prim("{F9}", "L"), "Delete", "P")
v::.

u::<
i::=
o::>
p::\

h::^
j::+
k::-
l::*
`;::/
vkBA::%

n::_
m::!
,::?
.:::
/::;

#HotIf GetKeyState("vk1d", "P")
*w::Click("WU")
*e::Click("WD")

*a::Send(KeyWait("r", "T0.2") ? "!^f" : "!+f") || KeyWait("x")
*s::Layer("Click R")
*d::Layer("Click")
*f::{
	MyGui := Gui("+AlwaysOnTop")
	MyGui.AddMonthCal()
	MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
	MyGui.Show()
	Send("{F13}")
}
x::+F14

#SuspendExempt true
u::Reload
i::Suspend(-1) || Notice("サスペンド " (A_IsSuspended ? "ON" : "OFF"))
o::KeyHistory

#SuspendExempt false
*h::
*j::
*k::
*l:: {
	MouseGetPos(&X, &Y)
	diff := GetKeyState("Ctrl", "P") ? 80 : 16
	X += GetKeyState("l", "P") ? diff : (GetKeyState("h", "P") ? -diff : 0)
	Y += GetKeyState("j", "P") ? diff : (GetKeyState("k", "P") ? -diff : 0)
	MouseMove(X, Y)
}
`;:: {
	WinGetPos(&X, &Y, &W, &H, "A")
	MouseGetPos(&offsetX, &offsetY)
	MX := Min(W, 1920 - X), MY := Min(H, 1080 - Y)
	◢ := (offsetY / MY + offsetX / MX) > 1
	◣ := (offsetY / MY - offsetX / MX) > 0
	MouseMove((◢ / 2 + !◢ * ◣) * MX, (!◢ / 2 + ◢ * !◣) * MY)
	Notice("ルパインアタック", 300)
}

*vk1c::global LastKey := Send("{Delete}")

#HotIf WinExist("ahk_exe AutoHotkey64.exe")
*w::Toggle("l", "{BS}ɫ")
*e::Toggle("u", "{BS}ʊ")

*LControl::Layer("Ctrl", "ə")
*a::Toggle("e", "{BS}ɛ")
*s::Toggle("i", "{BS}ɪ")
*d::Toggle(WithKey("a", "æ", "Ctrl"), WithKey("{BS}ɑ",, "Ctrl"))
*f::Toggle("o", "{BS}ɔ")
*g::Toggle(WithKey("ː", "ˈ", "Ctrl"), WithKey(, Prim("{BS}ˌ"), "Ctrl"))
*c::Toggle("v", "{BS}ʌ")

*u::Toggle(WithKey("r", "ɚ", "Ctrl"), Prim("{BS}" WithKey("ɹ", "ɝ", "Ctrl")))
*o::!GetKeyState("j", "P") && !GetKeyState(";", "P") ? Toggle("h", "{BS}ɾ") :
	Toggle("{BS}" WithKey("ʃ", "θ", "j"), "{BS}" WithKey("tʃ", "ð", "j"))

*l::Toggle("k", "{BS}ŋk", "k")
*vkBA::Toggle("j", "{BS}ʒ")

*.::Toggle("g", "{BS}ŋ", "k")

#HotIf WinActive("ahk_exe RPG_RT.exe")
*h::Layer("Left")
*j::Layer("Down")
*k::Layer("Up")
*l::Layer("Right")
*x::Layer("x")
*z::Layer("z")

Notice("終わったよ", 800)
