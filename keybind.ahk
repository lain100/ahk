#Requires AutoHotkey v2.0
#SingleInstance Force
OnClipboardChange ClipChanged

Mode.Init()
ClipHistory.Init()

class Mode {
  static IPA := false, Modifiers := Map()

  static Init() {
    this._Gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    this._Gui.BackColor := "202020"
    this.Label := this._Gui.AddText("cFFFFFF x6 y20 w108 h80 Center")
    this.Label.SetFont("s11", "Segoe UI")
    WinSetExStyle("+0x20", this._Gui.Hwnd)
  }

  static Into(key, value, mods := []) {
    (key = "IPA" ? (this.IPA := value) : (this.Modifiers[key] := value))
    for key, value in this.Modifiers
      value ? mods.Push(LTrim(key, "LR")) : ""
    this.Label.Text := Join(["", Join(mods, " + "), this.IPA ? "IPA" : ""], "`n")
    WinSetTransParent(200, this._Gui.Hwnd)
    this._Gui.Show("y200 w120 h100 NA")
    this.SetFadeOut(this._Gui, 200, mods.Length ? 0 : 100)
  }

  static SetFadeOut(_Gui, alpha := 255, time := 2000) {
    try your_id := ++this.%_Gui.Hwnd%
    catch
        your_id :=  (this.%_Gui.Hwnd% := 0)
    SetTimer((*) => this.FadeOut(_Gui, alpha, your_id), -time)
  }

  static FadeOut(_Gui, al, my_id, alpha := Max(al - 10, 0)) {
    if this.%_Gui.Hwnd% != my_id
      return
    (alpha ? WinSetTransparent(alpha, _Gui.Hwnd) : _Gui.Hide())
    Settimer((*) => this.FadeOut(_Gui, alpha, my_id), -15)
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
    if StrLen(newText) {
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
        if StrLen(newText)
          ClipHistoryEncodes.InsertAt(start, time "|" Base64Encode(newText))
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
  return Assign(lv, {_Gui: _Gui, filterEdit: filterEdit, showEdit: showEdit, row: row})
}

ShowClipHistory() {
  static lv := InitListView(20, 18)
  try {
    Assign(lv, {page: 1, targetText: ""}).filterEdit.Value := ""
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
      if targetRow && StrLen(lv.targetText) {
        time := 1
        ClipHistory.Modify(lv.targetText, newText)
        Tips((newText ? "保存" : "削除") "したよ")
      } else
        ((A_Clipboard := newText) (lv.page := 1) (targetRow := 1))
    } else if !ClipHistory.isChanged
      return
    ClipHistory.isChanged := false
    lv.targetText := ""
    SetTimer((*) => ApplyFilter(lv, targetRow), -time)
  }
}

ApplyFilter(lv, targetRow := 1) {
  ClipHistory.ApplyFilter(lv.FilterEdit.Value)
  lv.range := Max(Ceil(ClipHistory.Filtered.Length / lv.row), 1)
  lv.page := Min(lv.page, lv.range)
  ShowFiltered(lv)
  lv.Modify(Max(Min(targetRow, LVGetLength(lv)), 1), "Focus Select")
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

Mapcar(arr, fn, newArr := []) {
  for item in arr
    newArr.Push(fn(item))
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

ShowCalender() {
	static Calender := Gui("+AlwaysOnTop -Caption")
  WinSetTransParent(255, Calender.Hwnd)
  Mode.SetFadeOut(Calender)
	Calender.AddMonthCal()
	Calender.Show("NA")
}

WithKey(initValue := "", mapObj := Map(), cond := "P") {
  for key, value in mapObj
    if key && GetKeystate(key, cond)
      return value
  return initValue
}

Toggle(key := "", key2 := "", time := 0.3, mod := LTrim(A_ThisHotkey, "~+*``")) =>
  (SendEvent(key) (KeyWait(mod, "T" time) ? "" : SendEvent(key2)) KeyWait(mod))

ShowKey(key) => (Mode.Into(key, true) KeyWait(key) Mode.Into(key, false))

Search(url) => (SendEvent("^{c}") Settimer((*) => Run(url A_Clipboard), -100))

Tips(msg, delay := 1000) => (ToolTip(msg) SetTimer(ToolTip, -delay))

PairKeyWith    := Map()
TargetPriorKey := Mapcar(StrSplit("+, +2 [ +7 +8 +@ +[", " "), key => "~*" key)
for index, key in Mapcar(StrSplit("+. +2 ] +7 +9 +@ +]", " "), key => "~*" key)
  ( Hotkey(PairKeyWith[key] := TargetPriorKey[index], (*) => "")
    Hotkey(key, key =>  A_PriorHotkey = PairKeyWith[key] &&
                        A_TimeSincePriorHotkey <= 1000 ? SendEvent("{Left}") : ""))
for key in StrSplit("LCtrl LShift LWin RAlt", " ")
  Hotkey("~*" key, key => ShowKey(LTrim(key, "~*")))
F14::Volume_Down
F15::Volume_Up
F16::Browser_Home
F17::ShowClipHistory
F18::ShowCalender
F19::Search("https://www.google.com/search?q=")
F20::Search("https://translate.google.com/?sl=auto&tl=ja&text=")
F21::Search("https://web.archive.org/web/")
F22::Reload
F23::KeyHistory
F24::Mode.Into("IPA", !Mode.IPA)

#HotIf Mode.IPA
vk1c::ə
*l::Toggle("l", "{BS}ɫ")
*u::Toggle("u", "{BS}ʊ")
*i::Toggle("i", "{BS}ɪ")
*o::Toggle("o", "{BS}ɔ")
*v::Toggle("v", "{BS}ʌ")
*j::Toggle("j", "{BS}ʒ")
*a::Toggle(WithKey("a", Map("e", "{BS}æ")), WithKey("{BS}ɑ", Map("e", "")))
*-::Toggle(WithKey("ː", Map("e", "{BS}ˈ")), WithKey(, Map("e", "{BS}ˌ")))
*r::Toggle(WithKey("r", Map("e", "{BS}ɚ")), "{BS}" WithKey("ɹ", Map("e", "ɝ")))
*h::Toggle(WithKey("h", Map("t", "{BS}θ", "s", "{BS}ʃ", "c", "{BS}tʃ")),
           WithKey("{BS}ɾ", Map("t", "{BS}ð", "s", "", "c", "")))
~*k::SendEvent(WithKey(, Map("n", "{BS}{BS}ŋk")))
~*g::SendEvent(WithKey(, Map("n", "{BS}{BS}ŋ")))

#HotIf GetKeyState("n", "P")
k::n

#HotIf WinActive("ahk_exe RPG_RT.exe") || WinActive("ahk_exe Game.exe")
a::x
o::z
p::Left
t::Down
n::Up
k::Right

Tips("終わったよ", 800)
