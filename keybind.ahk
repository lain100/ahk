#Requires AutoHotkey v2
#SingleInstance force
OnClipboardChange ClipChanged

IME := -1, SandS := 0, IPA := 0, path := "clip_history" 

ClipChanged(type, time := DateAdd(A_NowUTC, 9, "Hours"), text := A_Clipboard) {
  static ClipHistory := ClipHistory_Init()
  if type != 1
    return ClipHistory
  ClipHistory_Remove(text, ClipHistory)
  ClipHistory.InsertAt(1, [time, text])
  FileAppend(time "|" Base64Encode(text) "`n", path, "UTF-8")
  if Substr(text, 1, 17) = "https://www.youtu" {
    try Run("C:\Program Files\MPC-BE\mpc-be64.exe /add " text)
  } else
    TryRunEgaroucid(text)
  Tips("コピーしたよ")
}

TryRunEgaroucid(text) {
  static app := "Egaroucid_7_8_0_SIMD.exe", board := StrSplit("f5 f4 d3 g6", " ")
  if !WinExist("ahk_exe " app) && Always(board, pos => InStr(text, pos))
    try Run("C:\Program Files\Egaroucid_7_8_0\" app)
}

ClipHistory_Init(code := "", ClipHistory := []) {
  for line in StrSplit(FileOpen(path, "rw").Read(), "`n", "`r") {
    if line = "" {
      if code = ""
        continue
      items := StrSplit(code, "|")
      items[2] := Join(StrSplit(Base64Decode(items[2]), "`n"), "`r`n")
      ClipHistory.InsertAt(1, items)
      code := ""
    } else
      code .= line
  }
  return ClipHistory
}

ClipHistory_IndexOf(text, ClipHistory) {
  for index, items in ClipHistory
    if text = items[2]
      return index
}

ClipHistory_Remove(text, ClipHistory, index := 1, start := 1) {
  targetIndex := ClipHistory_IndexOf(text, ClipHistory)
  if !targetIndex
    return
  ClipHistory.RemoveAt(targetIndex)
  targetIndex := ClipHistory.Length - targetIndex + 2
  ClipHistoryCodes := StrSplit(FileRead(path), "`n", "`r")
  for end, line in ClipHistoryCodes {
    if line = "" {
      if index = targetIndex {
        ClipHistoryCodes.RemoveAt(start, end - start + 1)
        FileOpen(path, "w").Write(Join(ClipHistoryCodes, "`n"))
      }
      index++
      start := end + 1
    }
  }
}

ShowClipHistory(r := 18, height := 40, theme := "cFFFFFF BackGround202020") {
  static MyGui := Gui(), ClipHistory := ClipChanged("Call Init")
  MyGui.Destroy()
  MyGui := Gui("+AlwaysOnTop -Caption")
  MyGui.BackColor := "202020"
  MyGui.OnEvent("Escape", (*) => ((Hwnd := false) MyGui.Destroy()))
  filterEdit := MyGui.AddEdit(theme " W700 H32 vFilter -Tabstop -Vscroll")
  filterEdit.SetFont("s12", "Segoe UI")
  filterEdit.OnEvent("Change", (ctrl, *) => ApplyFilter(lv, ctrl.Value))
  pageEdit := MyGui.AddEdit("X+M W39 vPage ReadOnly")
  pageEdit.OnEvent("Change", (ctrl, *) => ((lv.page := ctrl.Value - 1)
    (id := ++lv.id) SetTimer((*) => id && id = lv.id ? ShowFiltered(lv) : "", -100)))
  ud := MyGui.AddUpDown("Wrap")
  lv := MyGui.AddListView(theme " W750 XM Checked -Hdr H" r * 42, [""])
  lv.OnEvent("ItemCheck", (*) => (
    (A_Clipboard := lv.Filtered[lv.row * lv.page + lv.GetNext()][2]) MyGui.Destroy()))
  lv.OnEvent("ItemFocus", (*) => (
    (id := ++lv.id) SetTimer((*) => id = lv.id ? ShowItem(lv, viewEdit) : "", -200)))
  lv.OnEvent("ContextMenu", (*) => (RemoveItem(lv) ApplyFilter(lv, filterEdit.Value)))
  lv.Focus()
  ImageListID := DllCall("ImageList_Create", "Int", 1, "Int", height, "UInt", 0x18, "Int", 1, "Int", 1)
  SendMessage(0x1003, 1, ImageListID, lv.Hwnd, "ahk_id " lv.Gui.Hwnd)
  viewEdit := MyGui.AddEdit(theme " YM WP HP+40.4 ReadOnly -Tabstop -VScroll")
  viewEdit.SetFont("s12", "Consolas")
  Assign(lv, {row: r, page: 0, id: -1, ud: ud, ClipHistory: ClipHistory, Filtered: []})
  ApplyFilter(lv)
  MyGui.Show()
  try WinSetTransParent(200, MyGui.Hwnd)
}

RemoveItem(lv) {
  try {
    text := lv.Filtered[lv.row * lv.page + lv.GetNext()][2]
    ClipHistory_Remove(text, lv.ClipHistory)
    Tips("削除したよ")
  }
}

ApplyFilter(lv, keyword := "", value := lv.ud.Value) {
  lv.Filtered := keyword ? Filter(lv.ClipHistory, items => Instr(items[2], keyword))
                         : lv.ClipHistory.clone()
  limit := Ceil(lv.Filtered.Length / lv.row)
  lv.ud.Opt("Range" limit "-" Min(limit, 1))
  lv.ud.Value := Min(limit, Max(value, 1))
  (lv.ud.Value = value || lv.id = -1) ? ShowFiltered(lv) : ""
}

ShowFiltered(lv, start := lv.row * lv.page + 1) {
  try {
    lv.Delete()
    for items in Slice(lv.Filtered, start, start + lv.row - 1)
      lv.Add("", items[2])
  }
}

ShowItem(lv, viewEdit) {
  try {
    items := lv.Filtered[lv.row * lv.page + lv.GetNext()]
    viewEdit.Text := formatTime(items[1], "yyyy/MM/dd HH:mm:ss`r`n--`r`n") items[2]
  }
}

Slice(arr, start, end, newArr := []) {
  Loop (Min(arr.Length, end) - Max(start, 1) + 1)
    newArr.Push(arr[start + A_Index - 1])
  return newArr
}

Filter(arr, fn, newArr := []) {
  for item in arr
    fn(item) ? newArr.Push(item) : ""
  return newArr
}

Always(arr, fn) {
  for item in arr
    if fn(item) == false
      return false
  return true
}

Join(arr, sep := ",", str := "") {
  for index, param in arr
    str .= param (index = arr.Length ? "" : sep)
  return str
}

Assign(target, sources*) {
  for src in sources
    for key, value in src.OwnProps()
      target.%key% := value
  return target
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

for key in StrSplit("- ^ \ t y @ [ ] b vke2 Esc Tab LShift Lwin LAlt RAlt", " ")
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
*Delete::(Layer(, SandS ? "{Shift Up}" : WithKey("{vk1c}", "{Space}", "Space"))
  A_PriorKey = "Delete" ? ModeChange(SandS, !SandS && WithKey(1, IME, "Space")) : "")

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
p::AppsKey

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
      SendEvent(WithKey(WithKey(, Prim("{vkf2}{vkf3}", "L"), "n"),
                                  Prim("{vkf2}", "L"), "m")))
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
x::ShowClipHistory
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

#HotIf WinActive("ahk_exe AutoHotkey64.exe")
vk1d::Space

Tips("終わったよ", 800)
