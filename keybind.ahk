#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange Using_MPC_BE
OnClipboardChange ClipChanged

IME := -1, SandS := 0, IPA := 0, ClipHistory := [], Filtered := [], Label := ""
path := A_ScriptDir "\clip_history.txt"

InitClipHistory(str := "") {
  for line in StrSplit(FileRead(path), "`n", "`r") {
    if line = "" {
      if str
        ClipHistory.InsertAt(1, Base64Decode(str))
      str := ""
    } else
      str := str line
  }
}
InitClipHistory()

CheckDuplicate(text, str := "") {
  for line in StrSplit(FileRead(path), "`n", "`r") {
    if line = "" {
      if Base64Decode(str) = text
        return false
      str := ""
    } else
      str := str line
  }
  return true
}

ClipChanged(type) {
  global ClipHistory
  text := A_Clipboard
  if (type != 1 || text = "")
    return
  for idx, item in ClipHistory {
    if text = item {
      ClipHistory.RemoveAt(idx)
      break
    }
  }
  ClipHistory.InsertAt(1, text)
  if CheckDuplicate(text)
    FileAppend(Base64Encode(text) "`n", path, "UTF-8")
  tips("コピーしたよ")
}

ApplyFilter(lv, row, keyword := "") {
  global ClipHistory, Filtered := []
  lv.Delete()
  for item in ClipHistory {
    if keyword = "" || Instr(item, keyword) {
      Filtered.Push(item)
      if Filtered.Length <= row
        lv.Add("", item)
    }
  }
}

RollList(lv, row, page, start := page * row, end := start + row) {
  global Filtered
  lv.Delete()
  for idx, item in Filtered {
    if idx <= start
      continue
    if idx > end
      break
    lv.Add("", item)
  }
}

ShowFocusedItem(lv, start, time) {
  static id := 0
  your_id := ++id
  SetTimer((*) => your_id = id ? TryShowItem(lv, start) : "", -time)
}

TryShowItem(lv, start) {
  try tooltip(Filtered[start + lv.GetNext()])
}

Base64Encode(str) {
  bin := Buffer(StrPut(str, "UTF-8"))
  StrPut(str, bin, "UTF-8")
  return CryptBinaryToString(bin)
}

Base64Decode(b64) {
  bin := CryptStringToBinary(b64)
  return StrGet(bin, "UTF-8")
}

CryptBinaryToString(buf) {
  size := 0
  DllCall("Crypt32.dll\CryptBinaryToStringW", "Ptr", buf.Ptr, "UInt",
  buf.Size, "UInt", 1, "Ptr", 0, "UInt*", &size)
  out := Buffer(size * 2)
  DllCall("Crypt32.dll\CryptBinaryToStringW", "Ptr", buf.Ptr, "UInt",
  buf.Size, "UInt", 1, "Ptr", out.Ptr, "UInt*", &size)
  return StrGet(out)
}

CryptStringToBinary(str) {
  size := 0
  DllCall("Crypt32.dll\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", 1,
  "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
  buf := Buffer(size)
  DllCall("Crypt32.dll\CryptStringToBinaryW", "Str", str, "UInt", 0, "UInt", 1,
  "Ptr", buf.Ptr, "UInt*", &size, "Ptr", 0, "Ptr", 0)
  return buf
}

Lupine_Attack(mode := 1) {
	WinGetPos(&X, &Y, &W, &H, "A")
	MouseGetPos(&offsetX, &offsetY)
	MX := Min(W, 1920 - X), MY := Min(H, 1080 - Y)
	◢ := (offsetY / MY + offsetX / MX) > 1
	◣ := (offsetY / MY - offsetX / MX) > 0
  w1 := mode ? (◣ + !◣ / 2) : !◣ / 2
  w2 := mode ?  ◣ / 2 : (!◣ +  ◣ / 2)
	MouseMove((◢ ? w1 : w2) * MX, (◢ ? w2 : w1) * MY)
	Tips("ルパインアタック", 300)
}

Layer(key := "", key2 := "", HotKey := GetHotKey()) {
  static cord
  cord := HotKey = "vk1c" || HotKey = "vk1d" ? HotKey : ""
  ( SendEvent(key ? "{Blind}{" key " Down}" : "") KeyWait(HotKey)
    SendEvent(key ? "{Blind}{" key " Up}"   : ""))
	SendEvent(key2 && A_PriorKey = (HotKey = cord ? "" : HotKey) ? "{Blind}" key2 : "")
}

Prim(str, cond := "P") {
	for key in ["Ctrl", "Shift"]
    str := WithKey(str, "{" key " Up}" str "{" key " Down}", key, cond)
	return str
}

Toggle(key := "", key2 := "", trg := "", cond := "P", HotKey := GetHotKey()) =>
( SendEvent("{Blind}" WithKey(key, key2, trg, cond))
  trg || KeyWait(HotKey, "T0.2") ? "" : (SendEvent("{Blind}" key2) KeyWait(HotKey)))

GetHotKey(seed := A_ThisHotKey, HotKey := LTrim(seed, "~+*``")) =>
	InStr(HotKey, " up") ? SubStr(HotKey, 1, -3) : HotKey

Arpeggio(key := "", key2 := "", trg := GetHotKey()) =>
  SendEvent("{Blind}" (trg = GetHotKey(A_PriorHotKey) ? key2 : key))

WithKey(key := "", key2 := "", trg := "", cond := "P") =>
  trg && GetKeyState(trg, cond) ? key2 : key

Using_MPC_BE(*) => (Substr(A_Clipboard, 1, 17) = "https://www.youtu") &&
  Run("C:\Program Files\MPC-BE\mpc-be64.exe " A_Clipboard)

Search(url) => (SendEvent("^{c}") Sleep(100) Run(url A_Clipboard))

Tips(msg, delay := 1000) => (ToolTip(msg) SetTimer(ToolTip, -delay))

InitMode() {
  Box := Gui("+AlwaysOnTop -Caption +ToolWindow")
  global Label := Box.AddText("cFFFFFF x20 y20 w200 h80")
  Label.SetFont("s11", "Segoe UI")
  Box.BackColor := "202020"
  Box.Show("y200 w90 h100 NA")
  WinSetExStyle("+0x20", Box.Hwnd)
  WinSetTransParent(128, Box.Hwnd)
}
InitMode()

ModeChange(mode, bool) {
  global IME := mode = 0 ? bool : IME,
       SandS := mode = 1 ? bool : SandS,
         IPA := mode = 2 ? bool : IPA, Label
  Label.Text := ( (IME = -1 ? "" : (IME ? "かな" : "英字")) "`n"
                  (SandS ? "SandS" : "") "`n"
                  (A_isSuspended ? "Suspend": (IPA ? "IPA" : "")))
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
*vk1c::Layer(, "{BackSpace}")
*Space::(ModeChange(1, 1) Layer("Shift", "{Space}") ModeChange(1, 0))
*Delete::(Layer(, SandS ? "{Shift Up}" : WithKey("{vk1c}", "{Space}", "Space"))
          ModeChange(SandS, !SandS && WithKey(1, IME, "Space")))
#SuspendExempt false
#HotIf GetKeyState("vk1c", "P")
q::@
w::[
*e::Arpeggio('"', '"{Left}')
*r::Arpeggio("]", "]{Left}", "w")

a::#
*s::GetKeyState("Space", "P") ? Layer("LWin") : SendEvent("(")
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

#SuspendExempt true
*n::
*m::
*,::
*.::( ModeChange(0, WithKey(WithKey(IME, 0, "n"), 1, "m"))
      Suspend(WithKey(0, -1, ".")) ModeChange(2, WithKey(0, !IPA, ","))
      SendEvent(WithKey(WithKey(, Prim("{vkf2}{vkf3}"), "n"), Prim("{vkf2}"), "m")))
*/::Browser_Home

#SuspendExempt false
#HotIf GetKeyState("vk1d", "P")
*q::SendEvent("+{PrintScreen}")
*w::Click("WU")
*e::Click("WD")

*a::SendEvent(Prim(WithKey("!",, "Space") "{PrintScreen}", "L"))
*s::Layer("Click R")
*d::Layer("Click")
*f::{
	Calender := Gui("+AlwaysOnTop -Caption")
	Calender.AddMonthCal()
	Calender.Show("NA")
	(SendEvent("{F13}") SetTimer((*) => FadeOut(Calender), -2000))
}
z::!F4
x::{
  global ClipHistory, Filtered
  static g := Gui(), row := 40
  page := 0
  g.Destroy()
  g := Gui("+AlwaysOnTop -Caption")
  g.BackColor := "202020"
  lv := g.AddListView("cFFFFFF BackGround202020 Checked -Hdr r" row, ["Text"])
  filterEdit := g.AddEdit("vFilter")
  pageEdit := g.Add("Edit", "x+85 w50 vPage")
  g.AddUpDown("vUpDown Range" Ceil(ClipHistory.Length / row) "-1 Wrap")
  g.OnEvent("Escape", (*) => (tooltip() g.Destroy()))
  lv.OnEvent("ItemCheck", (*) => (A_Clipboard := Filtered[page * row + lv.GetNext()]
                                  g.Destroy()))
  lv.OnEvent("ItemFocus", (*) => ShowFocusedItem(lv, page * row, 200))
  filterEdit.OnEvent("Change", (ctrl, *) => ApplyFilter(lv, row, ctrl.value))
  pageEdit.OnEvent("Change", (ctrl, *) => ((page := ctrl.Value - 1)
                                            RollList(lv, row, page)))
  ApplyFilter(lv, row)
  g.Show()
  WinSetTransParent(200, g.Hwnd)
}
c::!Tab

#SuspendExempt true
u::Reload
i::KeyHistory
o::Volume_Down
p::Volume_Up

#SuspendExempt false
*h::
*j::
*k::
*l:: {
	MouseGetPos(&X, &Y)
	diff := 16 * WithKey(WithKey(1, 1/4, "LCtrl"), 5, "LShift")
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

h::Search("https://www.google.com/search?q=")
j::Search("https://translate.google.com/?sl=auto&tl=ja&text=")
k::Search("https://web.archive.org/web/")
l::Run("https://typingch.c4on.jp/game/index.html")
`;::Run("https://keyx0.net/easy/")
vkBA::Run("https://o24.works/atc/")

n::Run("https://drive.google.com/drive/u/0/my-drive")
m::Run("https://www.nct9.ne.jp/m_hiroi/clisp/index.html")
,::Run("http://damachin.web.fc2.com/SRPG/yaminabe/yaminabe00.html")
.::Run("https://jmh-tms2.azurewebsites.net/schoolsystem/")

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
*o::Arpeggio(">", ">{Left}", "u")
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

#HotIf IPA
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
