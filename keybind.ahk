#Requires AutoHotkey v2.0
#SingleInstance Force
OnClipboardChange ClipChanged

Mode.Init()
ClipHistory.Init()

class Mode {
  static id := 0, IME := -1, SandS := false, IPA := false

  static Init() {
    this._Gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    this._Gui.BackColor := "202020"
    this.Label := this._Gui.AddText("cFFFFFF x20 y20 w200 h80")
    this.Label.SetFont("s11", "Segoe UI")
    WinSetExStyle("+0x20", this._Gui.Hwnd)
  }

  static Into(value, key, oldValue := this.%key%) {
    this.%key% := value
    this.Label.Text := Join([
      this.IME = -1  ?         "" : ("      " (this.IME ? "あ" : "A")),
      this.SandS     ?  "  SHIFT" : "",
      A_isSuspended  ?  "SUSPEND" : (this.IPA ? "     IPA" : "")], "`n")
    WinSetTransParent(255, this._Gui.Hwnd)
    this._Gui.Show("y200 w100 h100 NA")
    this.SetFadeOut(this._Gui)
    return value != oldValue
  }

  static SetFadeOut(_Gui, time := 1000, id := ++this.id) {
    SetTimer((*) => this.FadeOut(_Gui, id), -time)
  }

  static FadeOut(_Gui, id, alpha := 255) {
    if id != this.id
      return
    WinSetTransparent(alpha := Max(alpha - 10, 0), _Gui.Hwnd) 
    Settimer((*) => alpha ? this.FadeOut(_Gui, id, alpha) : _Gui.Hide(), -15)
  }
}

class ClipHistory {
  static _ClipHistory := [], Filtered := [], isChanged := false, path := "clip_history"

  static Init(acc := "") {
    for line in StrSplit(FileOpen(this.path, "rw").Read(), "`n", "`r") {
      if line = "" {
        if acc = ""
          continue
        item := StrSplit(acc, "|")
        this._ClipHistory.Push([item[1], Base64Decode(item[2])])
        acc := ""
      } else
        acc .= line
    }
  }

  static ApplyFilter(keyword) {
    this.Filtered := keyword = "" ? this._ClipHistory.Clone() :
         Filter(this._ClipHistory, item => Instr(item[2], keyword))
  }

  static GetFocusItem(lv) {
    index := this.Filtered.Length - (lv.row * (lv.page - 1) + lv.GetNext()) + 1
    return this.Filtered[index]
  }

  static IndexOf(text) {
    for index, item in this._ClipHistory
      if item[2] = text
        return index
  }

  static Push(item) {
    this._ClipHistory.Push(item)
  }

  static Modify(targetText, newText := "", index := 1, start := 1) {
    targetIndex := this.IndexOf(targetText)
    if !targetIndex
      return
    if newText {
      time := this._ClipHistory[targetIndex][1]
      this._ClipHistory[targetIndex][2] := newText
    } else
      this._ClipHistory.RemoveAt(targetIndex)
    ClipHistoryEncodes := StrSplit(FileRead(this.path), "`n", "`r")
    for end, line in ClipHistoryEncodes {
      if line
        continue
      if index = targetIndex {
        ClipHistoryEncodes.RemoveAt(start, end - start + 1)
        newText ? ClipHistoryEncodes.InsertAt(start, time "|" Base64Encode(newText)) : ""
        FileOpen(this.path, "w").Write(Join(ClipHistoryEncodes, "`n"))
        return
      }
      index++
      start := end + 1
    }
  }

  static FileAppend(time, text) {
    FileAppend(time "|" Base64Encode(text) "`n", this.path, "UTF-8")
  }
}

ClipChanged(type, time := DateAdd(A_NowUTC, 9, "Hours"), text := A_Clipboard) {
  if type != 1
    return
  ClipHistory.Modify(text)
  ClipHistory.Push([time, text])
  ClipHistory.FileAppend(time, text)
  ClipHistory.isChanged := true
  Tips("コピーしたよ")
  static app := "Egaroucid_7_8_0_SIMD.exe", board := StrSplit("f5 f4 d3 g6", " ")
  switch {
    case Substr(text, 1, 8) = "https://" && InStr(text, "youtu"):
      try Run("C:\Program Files\MPC-BE\mpc-be64.exe /add " text)
    case !WinExist("ahk_exe " app) && Always(board, pos => InStr(text, pos)):
      try Run("C:\Program Files\Egaroucid_7_8_0\" app)
  }
}

InitListView(row, height) {
  OnMessage(0x0006, (wParam, *) => wParam = 0 ? _Gui.Hide() : "")
  OnMessage(0x007B, (*) => 0)
  OnMessage(0x0100, WM_KEYDOWN)
  OnMessage(0x0102, WM_CHAR)
  OnMessage(0x020A, WM_MOUSEWHEEL)
  WM_KEYDOWN(wParam, lParam, msg, hwnd) {
    switch hwnd {
      case lv.Hwnd:
        switch wParam {
          case 0x09: (showEdit.Text := "") showEdit.Focus()
          case 0x0D: CopyToClipBoard(lv)
          case 0x26: if ChangeFocusItem(lv, -1)
                      return 0
          case 0x28: if ChangeFocusItem(lv, 1)
                      return 0
          case 0x2E: SetTargetText(lv) ModifyTargetItem(lv)
        }
      case filterEdit.Hwnd:
        switch wParam {
          case 0x08: SendEvent(WithKey("{BS}", Map("Ctrl", "+^{Left}{BS}")))
          case 0x09: (showEdit.Text := "") showEdit.Focus()
          case 0x0D: CopyToClipBoard(lv)
          case 0x26: lv.Focus() ChangeFocusItem(lv, -1) ? "" : SendEvent("{Up}")
          case 0x28: lv.Focus() ChangeFocusItem(lv, 1) ? "" : SendEvent("{Down}")
          default:
            return ""
        }
        return 0
    }
  }
  WM_CHAR(wParam, lParam, msg, hwnd) {
    if hwnd == lv.Hwnd {
      filterEdit.Focus()
      SendEvent("{End}" Chr(wParam))
      return 0
    }
  }
  WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
    MouseGetPos(,,, &hCtrl, 2)
    if hCtrl == lv.Hwnd
      PageNext(lv, (wParam << 32 >> 48) > 0 ? -1 : 1)
  }
  static _Gui, lv, filterEdit, showEdit, theme := "cFFFFFF BackGround202020"
  _Gui := Gui("+AlwaysOnTop -Caption")
  _Gui.BackColor := "202020"
  _Gui.OnEvent("Escape", (*) => isFocused(showEdit) ? filterEdit.Focus() : _Gui.Hide())
  filterEdit := _Gui.AddEdit(theme " w750 h34 vFilter -Vscroll -WantReturn")
  filterEdit.SetFont("s12", "Segoe UI")
  filterEdit.OnEvent("Change", (*) => ApplyFilter(lv, lv.GetNext()))
  lv := _Gui.AddListView(theme " wp -Hdr -Tabstop h" 4 + 19 * row, [""])
  lv.OnEvent("ItemFocus", (*) => ShowFocusItem(lv))
  lv.OnEvent("DoubleClick", (*) => CopyToClipBoard(lv))
  showEdit := _Gui.AddEdit(theme " ym wp hp+42 -VScroll")
  showEdit.SetFont("s12", "Consolas")
  showEdit.OnEvent("Focus", (ctrl, *) => (Ctrl.Value := SetTargetText(lv)))
  showEdit.OnEvent("LoseFocus", (ctrl, *) => ModifyTargetItem(lv, ctrl.Value))
  ImgListID := DllCall("ImageList_Create" , "Int", 1, "Int", height,
                              "UInt", 0x18, "Int", 1, "Int", 1)
  SendMessage(0x1003, 1, ImgListID, lv.Hwnd, "ahk_id " lv.Gui.Hwnd)
  return Assign(lv, {_Gui: _Gui, filterEdit: filterEdit, showEdit: showEdit, row: row,
                     page: 1, range: 1, targetText: ""})
}

ShowClipHistory() {
  static lv := InitListView(20, 18)
  try {
    lv.filterEdit.Value := ""
    ApplyFilter(lv)
    lv._Gui.Show()
    WinSetTransParent(200, lv._Gui.Hwnd)
  } 
}

isFocused := (guiObj) => ControlGetFocus("A") == guiObj.Hwnd

CopyToClipboard := (lv) => ((A_Clipboard := GetFocusItem(lv)) lv._Gui.Hide())

SetTargetText := (lv) => (lv.targetText := GetFocusItem(lv))

Circulation := (cur, dir, len) => Mod(len + cur - 1 + Mod(dir, len), len) + 1

LVGetLength := (lv) =>
  Max(Min(ClipHistory.Filtered.Length - lv.row * (lv.page - 1), lv.row), 1)

ChangeFocusItem(lv, dir) {
  if GetKeyState("Shift", "L") {
    PageNext(lv, dir)
    return true
  } else {
    len := LVGetLength(lv)
    cur := lv.GetNext()
    row := Circulation(cur, dir, len)
    if some([1, len], val => row = val) {
      lv.Modify(cur, "-Focus -Select")
      lv.Modify(row, "Focus Select")
      ShowFocusItem(lv)
      return true
    }
  }
  return false
}

PageNext(lv, dir, targetRow := lv.GetNext()) {
  if lv.range = 1
    return
  lv.page := Circulation(lv.page, dir, lv.range)
  ShowFiltered(lv)
  lv.Modify(Max(Min(targetRow, LVGetLength(lv)), 1), "Focus Select")
  ShowFocusItem(lv)
}

GetFocusItem(lv) {
  try {
    if lv.GetNext() = 0
      throw
    return ClipHistory.GetFocusItem(lv)[2]
  } catch
    return ""
}

ModifyTargetItem(lv, newText := "", targetRow := lv.GetNext(), time := 100) {
  try {
    if lv.targetText != newText {
      if targetRow && lv.targetText {
        time := 1
        ClipHistory.Modify(lv.targetText, newText)
        Tips((newText ? "保存" : "削除") "したよ")
      } else
        ((A_Clipboard := newText) (targetRow := 1))
    } else if !ClipHistory.isChanged
      return
    ClipHistory.isChanged := false
    SetTimer((*) => ApplyFilter(lv, targetRow), -time)
  }
}

ApplyFilter(lv, targetRow := 1) {
  ClipHistory.ApplyFilter(lv.FilterEdit.Value)
  len := ClipHistory.Filtered.Length
  Assign(lv, {page: 1, range: Max(Ceil(len / lv.row), 1), targetText: ""})
  ShowFiltered(lv)
  lv.Modify(Max(Min(targetRow, len), 1), "Focus Select")
  ShowFocusItem(lv)
}

ShowFiltered(lv, end := ClipHistory.Filtered.Length - lv.row * (lv.page - 1)) {
  try {
    lv.Delete()
    lv.showEdit.Text := ""
    Filtered := Slice(ClipHistory.Filtered, Max(end - lv.row + 1, 1), end)
    Loop Filtered.Length
      lv.Add("", Filtered[Filtered.Length - A_Index + 1][2])
  }
}

ShowFocusItem(lv) {
  try {
    if isFocused(lv.showEdit)
      return
    item := ClipHistory.GetFocusItem(lv)
    lv.showEdit.Text :=
      "[" lv.row * (lv.page - 1) + lv.getNext() "/" ClipHistory.filtered.Length "] "
      . formatTime(item[1], "yyyy/MM/dd HH:mm:ss") "`r`n--`r`n"
      . StrReplace(item[2], "`n", "`r`n")
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

Some(arr, fn) {
  for item in arr
    if fn(item) == true
      return true
  return false
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

Toggle(key := "", key2 := "", time := 0.2, HotKey := GetHotKey()) =>
  (SendEvent("{Blind}" key) (KeyWait(HotKey, "T" time) ? "" :
  (SendEvent("{Blind}" key2) KeyWait(HotKey))))

RecentKey(initValue := "", mapObj := Map(), t := 0) {
  for key, value in mapObj
    if key && key = GetHotKey(A_PriorHotKey) && (t ? A_TimeSincePriorHotkey <= t : 1)
      return value
  return initValue
}

WithKey(initValue := "", mapObj := Map(), cond := "P") {
  for key, value in mapObj
    if key && GetKeystate(key, cond)
      return value
  return initValue
}

Prim(acc, cond := "L") {
  static keys := StrSplit("Ctrl Shift Alt", " ")
  for key in keys
    acc := WithKey(acc, Map(key, "{" key " Up}" acc "{" key " Down}"), cond)
  return acc
}

GetHotKey(seed := A_ThisHotKey, HotKey := LTrim(seed, "~+*``")) =>
  InStr(HotKey, " up") ? SubStr(HotKey, 1, -3) : HotKey

Search(url) => (SendEvent("^{c}") Settimer((*) => Run(url A_Clipboard), -100))

Tips(msg, delay := 1000) => (ToolTip(msg) SetTimer(ToolTip, -delay))

for key in StrSplit("- ^ \ t y @ [ ] b vke2 Esc Tab Lwin LAlt RAlt", " ")
  HotKey("*" key, (*) => "")

w::l
e::u
r::f

a::e
s::i
d::a
f::o
*g::SendEvent(WithKey("-", Map("Space", "%")))

*LShift::Layer(RecentKey("Shift", Map("LShift", "LWin"), 300))
z::x
x::c
c::v
*v::SendEvent(WithKey(",", Map("Space", Prim("."))))

u::r
i::y
o::h
p::w

h::p
j::t
k::n
*l::SendEvent("{Blind}" WithKey("k", Map("k", "n")))
`;::s
vkBA::j

n::b
m::d
,::m
.::g
/::z

#SuspendExempt true
vk1c & F24::
vk1d & F24::
Delete & F24::return
*vk1d Up::(A_PriorKey = "") && SendEvent("{Blind}{Enter}")
*vk1c Up::(A_PriorKey = "") && SendEvent("{Blind}{BackSpace}")
*Delete Up::(A_PriorKey = "Delete") && (Mode.Into(true, "IME") SendEvent("{vk1c}"))
*Space::(Mode.Into(true, "SandS") Layer("Shift", "{Space}") Mode.Into(false, "SandS"))

#SuspendExempt false
#HotIf GetKeyState("Space", "P") && GetKeyState("vk1c", "P")
u::<
i::=
*o::SendEvent(">" RecentKey(, Map("u", Prim("{Left}"))))
*p::SendEvent(Prim("\"))

*h::SendEvent(Prim("{^}"))
j::+
*k::SendEvent(Prim("-"))
l::$
*;::*
*vkBA::SendEvent(Prim("/"))

n::_
m::!
,::?
*.::SendEvent(Prim(":"))
*/::SendEvent(Prim(";"))

#HotIf GetKeyState("vk1c", "P")
*q::SendEvent(WithKey("@", Map("Space", "~")))
*w::SendEvent(WithKey("[", Map("Space", Prim("1"))))
*e::SendEvent(WithKey('"' RecentKey(, Map("e", "{Left}")), Map("Space", Prim("2"))))
*r::SendEvent(WithKey("]" RecentKey(, Map("w", "{Left}")), Map("Space", Prim("3"))))

*a::SendEvent(WithKey("{#}", Map("Space", Prim("0"))))
*s::SendEvent(WithKey("(", Map("Space", Prim("4"))))
*d::SendEvent(WithKey("'" RecentKey(, Map("d", "{Left}")), Map("Space", Prim("5"))))
*f::SendEvent(WithKey(")" RecentKey(, Map("s", "{Left}")), Map("Space", Prim("6"))))
g::&

*z::SendEvent(WithKey("{{}", Map("Space", Prim("7"))))
*x::SendEvent(WithKey("``" RecentKey(, Map("x", "{Left}")), Map("Space", Prim("8"))))
*c::SendEvent(WithKey("{}}" RecentKey(, Map("z", "{Left}")), Map("Space", Prim("9"))))
v::|

u::Esc
i::Tab
o::Delete
p::AppsKey

h::Left
j::Down
k::Up
l::Right
`;::Browser_Home
*vkBA::Layer("Alt")

#SuspendExempt true
*n::(Suspend(false) Mode.Into(false, "IPA") (Mode.Into(false, "IME") ? SendEvent(Prim("{vkf2}{vkf4}")) : ""))
m::Home
,::End
*.::(Suspend(false) Mode.Into(!Mode.IPA, "IPA"))
*/::(Suspend(-1) Mode.Into(false, "IPA"))

#SuspendExempt false
#HotIf GetKeyState("vk1d", "P")
*q::SendEvent("+{PrintScreen}")
*w::Click("WU")
*e::Click("WD")
*r::SendEvent("#^+R")

*a::SendEvent(Prim(WithKey("!", Map("Space", "")) "{PrintScreen}"))
*s::Click("R")
*d::Click
*f::{
	static Calender := Gui("+AlwaysOnTop -Caption")
  WinSetTransParent(255, Calender.Hwnd)
  Mode.SetFadeOut(Calender, 2000)
	Calender.AddMonthCal()
	Calender.Show("NA")
	SendEvent("{F13}")
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
	diff := 16 * WithKey(1, Map("LCtrl", 1/4, "LShift", 5))
	X += diff * WithKey(0, Map("l", 1, "h", -1))
	Y += diff * WithKey(0, Map("j", 1, "k", -1))
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

#HotIf Mode.IPA
*w::Toggle("l", "{BS}ɫ")
*e::Toggle("u", "{BS}ʊ")

*LControl::Layer("Ctrl", "ə")
*a::Toggle("e", "{BS}ɛ")
*s::Toggle("i", "{BS}ɪ")
*d::Toggle(WithKey("a", Map("Ctrl", "æ")), WithKey("{BS}ɑ", Map("Ctrl", "")))
*f::Toggle("o", "{BS}ɔ")
*g::Toggle(WithKey("ː", Map("Ctrl", "ˈ")), WithKey(, Map("Ctrl", Prim("{BS}ˌ"))))

*c::Toggle("v", "{BS}ʌ")

*u::Toggle(WithKey("r", Map("Ctrl", "ɚ")), Prim("{BS}") WithKey("ɹ", Map("Ctrl", "ɝ")))
*o::Toggle(WithKey("h", Map("j", "{BS}θ", ";", "{BS}ʃ", "x", "{BS}tʃ")),
           WithKey("{BS}ɾ", Map("j", "{BS}ð", ";", "", "x", "")))

*l::SendEvent(WithKey("k", Map("k", "{BS}ŋk")))
*vkBA::Toggle("j", "{BS}ʒ")

*.::SendEvent(WithKey("g", Map("k", "{BS}ŋ")))

#HotIf WinActive("ahk_exe RPG_RT.exe") || WinActive("ahk_exe Game.exe")
d::x
f::z
h::Left
j::Down
k::Up
l::Right

Tips("終わったよ", 800)
