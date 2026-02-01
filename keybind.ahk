#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange ClipChanged

IME := -1, SandS := 0, IPA := 0, ClipHistory := [], Filtered := []
path := A_ScriptDir "\clip_history.txt"

ClipChanged(type, text := A_Clipboard) {
  static ClipHistory := InitClipHistory()
  if type != 1
    return ClipHistory
  ClipHistory_Remove(text)
  ClipHistory.InsertAt(1, text)
  ClipHistory_File_Remove(text)
  FileAppend(Base64Encode(text) "`n", path, "UTF-8")
  if Substr(A_Clipboard, 1, 17) = "https://www.youtu"
    Run("C:\Program Files\MPC-BE\mpc-be64.exe " A_Clipboard)
  Tips("コピーしたよ")
}

InitClipHistory(str := "") {
  global ClipHistory, path
  for line in StrSplit(FileRead(path), "`n", "`r") {
    if line = "" {
      if str
        ClipHistory.InsertAt(1, Base64Decode(str))
      str := ""
    } else
      str .= line
  }
  return ClipHistory
}

ClipHistory_Remove(text) {
  global ClipHistory
  for idx, item in ClipHistory {
    if text = item {
      ClipHistory.RemoveAt(idx)
      return
    }
  }
}

ClipHistory_File_Remove(text, str := "", start := 1) {
  global path
  ClipHistoryFile := StrSplit(FileRead(path), "`n", "`r")
  for idx, line in ClipHistoryFile {
    if line = "" {
      if Base64Decode(str) = text {
        ClipHistoryFile.RemoveAt(start, idx - start + 1)
        FileOpen(path, "w").Write(Join(ClipHistoryFile, "`n"))
        return
      }
      str := ""
      start := idx + 1
    } else
      str .= line
  }
}

ShowClipHistory(row := 30, id := 0, page := 1) {
  global Filtered
  static g := Gui(), ClipHistory := ClipChanged(0)
  g.Destroy()
  g := Gui("+AlwaysOnTop -Caption")
  g.BackColor := "202020"
  g.OnEvent("Escape", (*) => (tooltip() g.Destroy()))
  lv := g.AddListView("cFFFFFF BackGround202020 Checked -Hdr r" row, ["Text"])
  lv.OnEvent("ItemCheck", (*) =>
    (A_Clipboard := Filtered[row * (page - 1) + lv.GetNext()] g.Destroy()))
  lv.OnEvent("ItemFocus", (*) => ( (your_id := ++id)
    SetTimer((*) => your_id = id ? ShowItem(lv, row, page) : "", -200)))
  lv.OnEvent("ContextMenu", (*) => RemoveItem(lv, row, page, filterEdit.Value))
  filterEdit := g.AddEdit("vFilter")
  filterEdit.OnEvent("Change", (ctrl, *) => (
    ApplyFilter(lv, row, page, ctrl.Value) (limit := Ceil(Filtered.Length / row))
    page := Min(limit, ud.Value) ud.Opt("Range" limit "-1")))
  pageEdit := g.Add("Edit", "x+85 w50 vPage ReadOnly")
  pageEdit.OnEvent("Change", (ctrl, *) => ( (your_id := ++id) (page := ctrl.Value)
    SetTimer((*) => your_id = id ? ShowFiltered(lv, row, page) : "", -100)))
  ud := g.AddUpDown("vNum Range" Ceil(ClipHistory.Length / row) "-1 Wrap")
  ApplyFilter(lv, row, page)
  g.Show()
  try WinSetTransParent(200, g.Hwnd)
}

RemoveItem(lv, row, page, keyword) {
  global Filtered
  try {
    text := Filtered[row * (page - 1) + lv.GetNext()]
    ClipHistory_Remove(text)
    ClipHistory_File_Remove(text)
    ApplyFilter(lv, row, page, keyword)
    Tips("削除したよ")
  }
}

ApplyFilter(lv, row, page, keyword := "") {
  global ClipHistory, Filtered := []
  for item in ClipHistory {
    if keyword = "" || Instr(item, keyword)
      Filtered.Push(item)
  }
  ShowFiltered(lv, row, page)
}

ShowFiltered(lv, row, page) {
  global Filtered
  try {
    lv.Delete()
    for item in Slice(Filtered, row * (page - 1) + 1, row * page)
      lv.Add("", item)
  }
}

ShowItem(lv, row, page) {
  try tooltip(Filtered[row * (page - 1) + lv.GetNext()])
}

Slice(arr, start, end, newArr := []) {
  Loop (Min(arr.Length, end) - Max(start, 1) + 1)
    newArr.Push(arr[start + A_Index - 1])
  return newArr
}

Join(arr, sep := ",", str := "") {
  for index, param in arr
    str .= param (index = arr.Length ? "" : sep)
  return str
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
  SendEvent(key ? "{Blind}{" key " Down}" : "") KeyWait(HotKey)
  SendEvent(key ? "{Blind}{" key " Up}"   : "")
  SendEvent(key2 && A_PriorKey = HotKey ? "{Blind}" key2 : "")
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

Search(url) => (SendEvent("{Blind}^{c}") Sleep(100) Run(url A_Clipboard))

Tips(msg, delay := 1000) => (ToolTip(msg) SetTimer(ToolTip, -delay))

InitMode() {
  Box := Gui("+AlwaysOnTop -Caption +ToolWindow")
  Lbl := Box.AddText("cFFFFFF x20 y20 w200 h80")
  Lbl.SetFont("s11", "Segoe UI")
  Box.BackColor := "202020"
  Box.Show("y200 w100 h100 NA")
  WinSetExStyle("+0x20", Box.Hwnd)
  WinSetTransParent(128, Box.Hwnd)
  return Lbl
}

ModeChange(mode, bool) {
  static Label := InitMode()
  global IME := mode = 0 ? bool : IME,
       SandS := mode = 1 ? bool : SandS,
         IPA := mode = 2 ? bool : IPA
  Label.Text := Join([ IME = -1 ?        "" : "   " (IME ? "かな" : "英字"),
                          SandS ? "  SHIFT" : "",
                  A_isSuspended ? "SUSPEND" : (IPA ? "    IPA" : "")], "`n")
}

FadeOut(g, alpha := 255, a := Max(alpha - 10, 0)) =>
  Settimer((*) => a ? (WinSetTransparent(a, g.Hwnd) FadeOut(g, a)) : g.Destroy(), -15)

for key in StrSplit("- ^ \ t y @ [ ] b vke2 Esc Delete Tab LShift Lwin LAlt RAlt", " ")
  HotKey("*" key, (*) => "")

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
vk1c & F24::
vk1d & F24::return
*vk1d Up::SendEvent(A_PriorKey = "" ? "{Blind}{Enter}" : "")
*vk1c Up::SendEvent(A_PriorKey = "" ? "{Blind}{BackSpace}" : "")
*Space::(ModeChange(1, 1) Layer("Shift", "{Space}") ModeChange(1, 0))
*Delete Up::(SendEvent(A_PriorKey != "Delete" ? "" : "{Blind}"
            (SandS ? "{Shift Up}" : WithKey("{vk1c}", "{Space}", "Space")))
  ModeChange(SandS, !SandS && WithKey(1, IME, "Space")))

#SuspendExempt false
#HotIf GetKeyState("vk1c", "P")
q::@
w::[
*e::Arpeggio('"', '"{Left}')
*r::Arpeggio("]", "]{Left}", "w")

a::#
*s::GetKeyState("Space", "P") ? Layer("LWin") : SendEvent("{Blind}(")
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
x::ShowClipHistory()
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
