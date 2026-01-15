#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange Using_MPC_BE

SandS := 0, IPA_Mode := 0, LastKey := "", LayerGui := Gui()

Lupine_Attack(mode := 1) {
	WinGetPos(&X, &Y, &W, &H, "A")
	MouseGetPos(&offsetX, &offsetY)
	MX := Min(W, 1920 - X), MY := Min(H, 1080 - Y)
	◢ := (offsetY / MY + offsetX / MX) > 1
	◣ := (offsetY / MY - offsetX / MX) > 0
  v := !mode * !◣ / 2 + mode * (◣ + !◣ / 2)
  w := mode * ◣ / 2 + !mode * (!◣ + ◣ / 2)
	MouseMove((◢ * v + !◢ * w) * MX, (!◢ * v + ◢ * w) * MY)
	Tips("ルパインアタック", 300)
}
Layer(key := "", key2 := "", HotKey := GetHotKey(), isSpace := Hotkey = "Space") {
  global SandS, LastKey := WithKey(, HotKey, HotKey = "vk1c" || HotKey = "vk1d")
  Send(WithKey(, "{Blind}{" key " Down}", (SandS && isSpace) || (key && !isSpace)))
	KeyWait(HotKey)
	Send(WithKey(, "{Blind}{" key " Up}", key && true))
	HotKey := WithKey(HotKey,, LastKey = HotKey)
	Send(WithKey(, "{Blind}" key2, key2 && A_PriorKey = HotKey))
}
Prim(str, cond := "P") {
	for key in ["Ctrl", "Shift"]
    str := WithKey(str, "{" key " Up}" str "{" key " Down}", key, cond)
	return str
}
Toggle(key := "", key2 := "", trg := "", cond := "P", HotKey := GetHotKey()) {
	Send("{Blind}" WithKey(key, key2, trg, cond))
	if key2 && !(trg || KeyWait(HotKey, "T0.2"))
	  (Send("{Blind}" key2) KeyWait(HotKey))
}
GetHotKey(seed := A_ThisHotKey, HotKey := LTrim(seed, "~+*``")) =>
	InStr(HotKey, " up") ? SubStr(HotKey, 1, -3) : HotKey

Arpeggio(key := "", key2 := "", trg := GetHotKey()) =>
  Send("{Blind}" PriorKey(key, key2, trg))

PriorKey(key := "", key2 := "", trg := GetHotKey()) =>
  WithKey(key, key2, trg = GetHotKey(A_PriorHotKey))

WithKey(key := "", key2 := "", trg := "", cond := "P") =>
  trg && (isInteger(trg) || GetKeyState(trg, cond)) ? key2 : key

Using_MPC_BE(*) => InStr(A_Clipboard, "youtu") &&
  Run("C:\Program Files\MPC-BE\mpc-be64.exe " A_Clipboard)

Search(url) => (Send("^{c}") Sleep(100) Run(url . A_Clipboard))

Tips(str, delay := 1000) => (ToolTip(str) SetTimer(ToolTip, -delay))

Notice(str, mode := 0) {
  g := Gui("+AlwaysOnTop -Caption +ToolWindow")
  g.BackColor := "202020"
  g.AddText("cFFFFFF x20 y20 w200 h80", str).SetFont("s11", "Segoe UI")
  g.Show("w120 h80 NA")
  Settimer((*) => FadeOut(255, g), -1000)
  mode ? UpDateStates(str) : ""
}

FadeOut(a, g, alpha := a - 10) {
  Settimer((*) => (alpha > 0) ?
    (WinSetTransparent(alpha, g.Hwnd) FadeOut(alpha, g)) : g.Destroy(), -30)
}

UpDateStates(str := "") {
  global SandS, IPA_Mode, LayerGui
  LayerGui.Destroy()
  LayerGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
  LayerGui.BackColor := "202020"
  LayerGui.AddText("cFFFFFF x20 y20 w200 h80", str
    "`nSandS " WithKey("OFF", "ON", SandS)
    "`nIPA " WithKey("OFF", "ON", IPA_Mode)).SetFont("s11", "Segoe UI")
  LayerGui.Show("x1800 w120 h100 NA")
  WinSetTransparent(128, LayerGui.Hwnd)
}
(LayerGui.Show() UpDateStates())

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
*g::Toggle("-", "$", "Space")

z::x
x::c
c::v
*v::Toggle(",", Prim(".", "L"), "Space")

u::r
i::y
o::h
p::w

h::p
j::t
k::n
*l::Layer(WithKey("k", "n", "k"))
`;::s
vkBA::j

n::b
m::d
,::m
.::g
/::z

*vk1d::Layer(, "{Enter}")
*Space::Layer("Shift", "{Space}")
*vk1c::Layer(, "{BackSpace}")
*Delete:: {
  if KeyWait("Delete") && A_PriorKey = "Delete" {
    global SandS := !SandS
    Notice("SandS " WithKey("OFF", "ON", SandS), 1)
    Send(WithKey("{Shift Up}", WithKey(, "{Shift Down}", "Space"), SandS))
  }
}

#HotIf GetKeyState("vk1c", "P")
q::@
*w::Arpeggio("[", "{Left}[", "r")
*e::Arpeggio('"', '"{Left}')
*r::Arpeggio("]", "]{Left}", "w")

a::#
*s::GetKeyState("Space", "P") ? Layer("LWin") : Arpeggio("(", "{Left}(", "f")
*d::GetKeyState("Space", "P") ? Layer("LAlt") : Arpeggio("'", "'{Left}")
*f::Arpeggio(")", "){Left}", "s")
g::&

*z::Arpeggio("{{}", "{Left}{{}", "c")
*x::Arpeggio("``", "``{Left}")
*c::Arpeggio("{}}", "{}}{Left}", "z")
v::|

u::Esc
i::Tab
o::Delete
p::vk5d

h::Left
j::Down
k::Up
l::Right
`;::Home
vkBA::End

*n::
*m::
*,::
*.:: {
  global IPA_Mode := WithKey(0, !IPA_Mode, ".")
  Send(WithKey(Prim(WithKey(, "+", ",") "{vkf2}" WithKey(, "{vkf3}", "n")),, "."))
  Notice(WithKey(WithKey(WithKey("半角", "かな", "m"), "カナ", ",") " モード",
    "IPA " WithKey("OFF", "ON", IPA_Mode), "."), 1)
}

#SuspendExempt true
/::(Suspend(-1) Notice("サスペンド " WithKey("OFF", "ON", A_IsSuspended)))

#SuspendExempt false
#HotIf GetKeyState("vk1d", "P")
*w::Click("WU")
*e::Click("WD")

*a::Send(Prim(WithKey("!",, "Space") "{PrintScreen}", "L"))
*s::Layer("Click R")
*d::Layer("Click")
*f::{
	Cal := Gui("+AlwaysOnTop -Caption")
	Cal.AddMonthCal()
	Cal.Show("NA")
	SetTimer((*) => Cal.Destroy(), -2000)
	Send("{F13}")
}
x::+F14
*c::Send("+{PrintScreen}")

u::Reload
i::KeyHistory
o::!Tab
p::!F4

*h::
*j::
*k::
*l:: {
	MouseGetPos(&X, &Y)
	diff := 16 * WithKey(1, 5, "LShift")
	X += diff * WithKey(WithKey(0, 1, "l"), -1, "h")
	Y += diff * WithKey(WithKey(0, 1, "j"), -1, "k")
	MouseMove(X, Y)
}
*`;::Lupine_Attack(GetKeyState("LShift", "P"))
*vkBA:: {
	WinGetPos(&X, &Y, &W, &H, "A")
	MouseMove(Min(W, 1920 - X) / 2, Min(H, 1080 - Y) / 2)
}

n::Volume_Mute
m::Volume_Up
,::Volume_Down

*vk1c::global LastKey := Send("{vk1c}")

#HotIf GetKeyState("Delete", "P")
q::F11
w::F1
e::F2
r::F3

a::F10
s::F4
d::F5
f::F6

LShift::F12
z::F7
x::F8
c::F9

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
.::Run("http://damachin.web.fc2.com/SRPG/yaminabe/yaminabe00.html")
/::Browser_Home

#HotIf GetKeyState("Space", "P") && !SandS
q::~
w::1
e::2
r::3

a::0
s::4
d::5
f::6

LShift::\
z::7
x::8
c::9

u::<
i::=
o::>

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

#HotIf IPA_Mode
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
*o::Toggle(WithKey(WithKey(WithKey("h", "{BS}θ", "j"), "{BS}ʃ", ";"), "{BS}tʃ", "x"),
           WithKey(WithKey("{BS}" WithKey("ɾ", "ð", "j"),"{F16}", ";"), "{F16}", "x"))

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

Tips("終わったよ", 800)
