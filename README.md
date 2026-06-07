# ZephyrUI — Shared GUI Library

แยก ZephyrUI ออกมาเป็นไฟล์เดียวเพื่อโหลดจาก GitHub แล้วใช้ร่วมกันหลายสคริปต์
(DA AutoFarm, ESP Hub, ฯลฯ) ทำให้สคริปต์หลักสั้นลงมาก

## ไฟล์

| ไฟล์ | คำอธิบาย | ขนาด |
|------|----------|------|
| `ZephyrUI.lua` | ไลบรารี GUI (อัปขึ้น GitHub) | ~1600 บรรทัด |
| `DA_AutoFarm_Merged.lua` | สคริปต์ฟาร์ม (โหลด lib จาก GitHub) | 9247 → ~8150 บรรทัด |
| `ESPHub_Complete.lua` | สคริปต์ ESP (โหลด lib จาก GitHub) | 2983 → ~1410 บรรทัด |

## วิธีตั้งค่า

### 1. อัป `ZephyrUI.lua` ขึ้น GitHub
สร้าง repo (เช่น `myname/da-scripts`) แล้วอัปไฟล์ `ZephyrUI.lua` เข้าไป

### 2. แก้ URL ในสคริปต์หลัก
ทั้ง `DA_AutoFarm_Merged.lua` และ `ESPHub_Complete.lua` มีบรรทัด:

```lua
local URL = "https://raw.githubusercontent.com/USER/REPO/main/ZephyrUI.lua"
```

เปลี่ยน `USER/REPO` เป็นของจริง เช่น:

```lua
local URL = "https://raw.githubusercontent.com/myname/da-scripts/main/ZephyrUI.lua"
```

> หมายเหตุ: ใช้ `raw.githubusercontent.com` ไม่ใช่ `github.com`
> ถ้าเปลี่ยน branch จาก `main` เป็นอย่างอื่นก็แก้ตรง `/main/` ด้วย

### 3. รันสคริปต์หลักได้เลย
สคริปต์จะ `game:HttpGet(URL)` แล้ว `loadstring(...)()` ดึงไลบรารีมาใช้อัตโนมัติ

## โครงสร้าง (ฝั่งสคริปต์หลัก)

```lua
local Zephyr = (function()
    local URL = "https://raw.githubusercontent.com/USER/REPO/main/ZephyrUI.lua"
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(URL))()
    end)
    if ok and type(lib) == "table" then return lib end
    error("Failed to load ZephyrUI: " .. tostring(lib))
end)()
```

## Public API ของ ZephyrUI

```lua
local win = Zephyr.Window({ Title = "My Hub", Subtitle = "v1" })
local tab = win:Tab("Main")
tab:Section("General")
tab:Toggle({ Text = "Enable", Default = false, Callback = function(v) end })
tab:Button({ Text = "Run", Callback = function() end })
tab:Slider({ Text = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
tab:Dropdown({ Text = "Mode", Options = {"A","B"}, Callback = function(o) end })
tab:Keybind({ Text = "Toggle", Default = Enum.KeyCode.F, Callback = function() end })
local lbl = tab:Label("status")
lbl:Set("updated")

Zephyr.Notify({ Title = "Hi", Content = "loaded", Duration = 3 })
Zephyr.SetTheme({ ACCENT = Color3.fromRGB(255,0,0) })
win:SetAccent("Red")   -- ใช้ preset ใน Zephyr.Accents
win:Destroy()
```

## ข้อดี
- แก้ UI ที่เดียว (`ZephyrUI.lua`) ทุกสคริปต์อัปเดตพร้อมกัน
- สคริปต์หลักสั้นลง ~1100–1600 บรรทัดต่อไฟล์
- เพิ่มสคริปต์ใหม่ก็แค่โหลด lib เดียวกัน

## ข้อควรระวัง
- ต้องมีเน็ตตอนรัน (โหลดจาก GitHub)
- executor ต้องรองรับ `game:HttpGet` (ส่วนใหญ่รองรับ)
- ปุ่ม close เปลี่ยนจาก `✕` เป็น `X` แล้ว (บาง executor ฟอนต์ไม่มี glyph `✕` เลยขึ้นเป็นกล่องสี่เหลี่ยม)
