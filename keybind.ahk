#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange Using_MPC_BE

SandS := 0, IPA_Mode := 0

Lupine_Attack(mode := 1) {
	WinGetPos(&X, &Y, &W, &H, "A")
	MouseGetPos(&offsetX, &offsetY)
	MX := Min(W, 1920 - X), MY := Min(H, 1080 - Y)
	◢ := (offsetY / MY + offsetX / MX) > 1
	◣ := (offsetY / MY - offsetX / MX) > 0
  v := WithKey(!◣ / 2, ◣ + !◣ / 2, mode)
  w := WithKey(!◣ + ◣ / 2,  ◣ / 2, mode)
	MouseMove(WithKey(w, v, ◢) * MX, WithKey(v, w, ◢) * MY)
	Tips("ルパインアタック", 300)
}

Layer(key := "", key2 := "", HotKey := GetHotKey()) {
  global SandS
  static cord
  cord := WithKey(, HotKey, HotKey = "vk1c" || HotKey = "vk1d")
  Send(WithKey(, "{Blind}{" key " Down}", WithKey(key && 1, SandS, HotKey = "Space")))
	KeyWait(HotKey)
	Send(WithKey(, "{Blind}{" key " Up}", key && 1))
	Send(WithKey(, "{Blind}" key2, key2 && A_PriorKey = WithKey(HotKey,, HotKey = cord)))
}

Prim(str, cond := "P") {
	for key in ["Ctrl", "Shift"]
    str := WithKey(str, "{" key " Up}" str "{" key " Down}", key, cond)
	return str
}

Toggle(key := "", key2 := "", trg := "", cond := "P", HotKey := GetHotKey()) =>
	(Send("{Blind}" WithKey(key, key2, trg, cond))
    trg || KeyWait(HotKey, "T0.2") ? "" : (Send("{Blind}" key2) KeyWait(HotKey)))

GetHotKey(seed := A_ThisHotKey, HotKey := LTrim(seed, "~+*``")) =>
	WithKey(HotKey, SubStr(HotKey, 1, -3), InStr(HotKey, " up"))

Arpeggio(key := "", key2 := "", trg := GetHotKey()) =>
  Send("{Blind}" WithKey(key, key2, trg = GetHotKey(A_PriorHotKey)))

WithKey(key := "", key2 := "", trg := "", cond := "P") =>
  trg && (isInteger(trg) || GetKeyState(trg, cond)) ? key2 : key

Using_MPC_BE(*) => InStr(A_Clipboard, "youtu") &&
  Run("C:\Program Files\MPC-BE\mpc-be64.exe " A_Clipboard)

Search(url) => (Send("^{c}") Sleep(100) Run(url A_Clipboard))

Tips(msg, delay := 1000) => (ToolTip(msg) SetTimer(ToolTip, -delay))

Notice(str := "") {
  global SandS, IPA_Mode
  static txt := "", msg:= Gui()
  txt := WithKey(txt, str, str && true)
  box := Gui("+AlwaysOnTop -Caption +ToolWindow")
  box.BackColor := "202020"
  box.Show("y200 w90 h100 NA")
  SetTimer((*) => FadeOut(box), -1000)
  msg.Destroy()
  msg := Gui("+AlwaysOnTop -Caption +ToolWindow")
  msg.BackColor := "202020"
  msg.AddText("cFFFFFF x20 y20 w200 h80", txt
    "`n" WithKey(, "SandS", SandS)
    "`n" WithKey(, "IPA", IPA_Mode) WithKey(, "Suspend", A_isSuspended))
  .SetFont("s11", "Segoe UI")
  msg.Show("y200 w90 h100 NA")
  WinSetExStyle("+0x20", msg.Hwnd)
  WinSetTransColor(msg.BackColor, msg.Hwnd)
}

FadeOut(g, alpha := 255, a := Max(alpha - 10, 0)) =>
  Settimer((*) => a ? (WinSetTransparent(a, g.Hwnd) FadeOut(g, a)) : g.Destroy(), -15)

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
*l::Toggle("k", "n", "k")
`;::s
vkBA::j

n::b
m::d
,::m
.::g
/::z

#SuspendExempt true
*vk1d::Layer(, "{Enter}")
*Space::{
  global SandS := WithKey(1, !SandS, A_PriorKey = "Space")
  (Suspend(0) Notice() Layer(WithKey(, "Shift", SandS))) 
}
*vk1c::Layer(, "{BackSpace}")
*Delete::Layer(, "{Space}")

#SuspendExempt false
#HotIf GetKeyState("vk1c", "P")
q::@
w::[
*e::Arpeggio('"', '"{Left}')
*r::Arpeggio("]", "]{Left}", "w")

a::#
*s::GetKeyState("Space", "P") ? Layer("LWin") : Send("(")
*d::GetKeyState("Space", "P") ? Layer("LAlt") : Arpeggio("'", "'{Left}")
*f::Arpeggio(")", "){Left}", "s")
g::&

z::`{
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

,::vk1c
, Up::Notice("かな")

#SuspendExempt true
*n::
*m::
*.::
*/::{
  global IPA_Mode := WithKey(0, !IPA_Mode, ".")
  Suspend(WithKey(0, -1, "/"))
  Send(WithKey(WithKey(, Prim("{vkf2}{vkf3}"), "n"), Prim("{vkf2}"), "m"))
  Notice(WithKey(WithKey(, "半角", "n"), "かな", "m"))
}

#SuspendExempt false
#HotIf GetKeyState("vk1d", "P")
*q::Send("+{PrintScreen}")
*w::Click("WU")
*e::Click("WD")

*a::Send(Prim(WithKey("!",, "Space") "{PrintScreen}", "L"))
*s::Layer("Click R")
*d::Layer("Click")
*f::{
	Calender := Gui("+AlwaysOnTop -Caption")
	Calender.AddMonthCal()
	Calender.Show("NA")
	(Send("{F13}") SetTimer((*) => FadeOut(Calender), -2000))
}
z::!F4
x::+F14
c::!Esc

u::Reload
i::KeyHistory
o::Volume_Down
p::Volume_Up

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

#HotIf GetKeyState("Delete", "P")
q::F11
w::F1
e::F2
r::F3

a::F10
s::F4
d::F5
f::F6
g::F12

z::F7
x::F8
c::F9

u::Run("https://x.com/husino93/with_replies")
i::Run("https://x.com/489wiki")
o::Run("https://bsky.app/profile/489wiki.bsky.social")
p::Run("https://scrapbox.io/gakkaituiho/")

h::Search("https://www.oxfordlearnersdictionaries.com/definition/english/")
j::Search("https://www.etymonline.com/search?q=")
k::Search("https://translate.google.com/?sl=auto&tl=ja&text=")
l::Run("https://typingch.c4on.jp/game/index.html")
`;::Run("https://keyx0.net/easy/")
vkBA::Run("https://o24.works/atc/")

n::Run("https://drive.google.com/drive/u/0/my-drive")
m::Run("https://www.nct9.ne.jp/m_hiroi/clisp/index.html")
,::Run("http://damachin.web.fc2.com/SRPG/yaminabe/yaminabe00.html")
.::Run("https://jmh-tms2.azurewebsites.net/schoolsystem/")
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

z::7
x::8
c::9

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
           WithKey(WithKey("{BS}" WithKey("ɾ", "ð", "j"),, ";"),, "x"))

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
