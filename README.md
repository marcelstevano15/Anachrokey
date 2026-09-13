# Anachrokey

Windows 7 and Windows 8.1/10 keyboard shortcuts, brought back to Windows XP.

XP never got `Win+Left/Right` snapping, `Win+X`, `Win+V`, or a working `Win+PrintScreen`. This script exists because I got tired of muscle memory failing me every time I sat down at an XP box, and because XP is still perfectly usable hardware-wise on a lot of old machines that just can't run anything newer. Anachrokey doesn't try to reskin XP into looking like Windows 10 — it only reimplements the *behavior* of those newer shortcuts on top of what XP already has.

Written for AutoHotkey **1.1** (last support AutoHotKey for Windows XP and the classic syntax, not v2). If you try to run this on AHK v2 it will throw errors immediately — the OS not supported and the command syntax is not compatible.

This project is still actively being developed. Most of the shortcuts below are stable, but `Win+V` (clipboard history) and `Win+Shift+S` (region screenshot) are experimental — they work, but they haven't been battered on enough different XP setups yet for me to call them finished. Expect rough edges there and treat the rest as the more dependable part of the tool.

---

## What it does

| Shortcut | Behavior |
|---|---|
| `Ctrl+Shift+N` | New Folder — works on the Desktop directly, or through the File menu inside Explorer's classic view |
| `Win+Up` | Maximize the active window |
| `Win+Down` | Restore if maximized, minimize if already restored |
| `Win+Left` | Snap window to the left half of the screen (press again to undo) |
| `Win+Right` | Snap window to the right half of the screen (press again to undo) |
| `Win+Home` | Minimize every window except the one you're currently using |
| `Win+B` (Currently is not work on initial release, still under development) | Jump focus to the system tray |
| `Win+PrintScreen` | Full-screen screenshot, saved automatically to `Pictures\Screenshots` as PNG|
| `Win+Shift+S` *(experimental)* | Drag-select a region of the screen and save it as an image (Snipping Tool style, dimmed overlay included) |
| `Win+X` | Quick Link menu — Control Panel, Device Manager, Task Manager, Services, Regedit, and the rest of the usual admin shortcuts, right from the keyboard |
| `Win+V` *(experimental)* | Clipboard history — keeps your last 10 copied text snippets, double-click one to paste it back onto the clipboard |
| `Win+,` | Peek at the desktop — minimizes everything, press again to bring it all back exactly as it was |
| `Win+Shift+Left` / `Win+Shift+Right` | Throw the active window over to the next monitor, if you've got more than one |

Fixed-size windows (Run dialog, About boxes, message boxes, Winver, and similar) are deliberately excluded from the maximize/restore/snap hotkeys — trying to maximize a dialog box that was never meant to resize just looks broken, so the script checks the window style first and backs off if it's not resizable.

---

## Important Limitations for Initial Release (v1.0.0)
- **Language dependency:** Ctrl+Shift+N's "New Folder" action outside the Desktop relies on English-language Explorer menu access keys (File → New → Folder). This will not work correctly on non-English Windows XP installations.
- **Hotkey conflict:** Ctrl+Shift+N is a system-wide hotkey and will intercept the same shortcut in other applications — most notably browsers (Chrome/Firefox use Ctrl+Shift+N for Incognito/Private Window). Disable this hotkey in the script if you rely on that shortcut elsewhere.
- Win+Left/Right/Up/Down window snapping may not respond in full-screen exclusive-mode applications and games that capture the Windows key.
- Win+V clipboard history tracks plain text only — copied images and files are not recorded.
- Win+B requires the default Windows Explorer shell (relies on the standard tray notification window class) and may not work under third-party shell replacements.

---


## Requirements

- **Windows XP SP3** at minimum. Earlier service packs are not tested and not supported — AutoHotKey 1.1 not support Windows XP SP2 and below, a lot of the `DllCall` and window-style checks this script relies on assume SP3-level Explorer/shell behavior. The version of AutoHotKey also limits XP SP2 and below.
- Nothing else, if you're using the compiled exe. It's a standalone binary — no AutoHotkey runtime, no separate library files to chase down.

---

## Dependencies

- [Gdip_All.ahk](https://github.com/marius-sucan/AHK-GDIp-Library-Compilation/blob/master/ahk-v1-1%2FGdip_All.ahk) — GDI+ wrapper library by tic (Tariq Porter), maintained/updated by marius-sucan. Handles the screenshot and screen-region-capture logic. It's already compiled into `Anachrokey.exe`, so this is here for credit and reference, not something you need to install separately.

If you're building from the `.ahk` source instead of using the prebuilt exe, you'll additionally need:

- AutoHotkey **1.1** (from ahkscript.org — not v2, the syntax and Operating System isn't compatible)
- `Gdip_All.ahk` placed in the same folder as the script before running it, since it's pulled in through `#Include` and isn't bundled with the source file itself.

---

## Installation

**Using the compiled exe (recommended for most people):**

1. Download `Anachrokey.exe`.
2. Run it. No installer, no dependencies to chase down — everything needed is already inside the exe.

**Building from source instead:**

1. Install AutoHotkey 1.1 — get it from the official downloads page: https://www.autohotkey.com/download/1.1/ (the site defaults to v2 now, so don't grab that; the direct link for the latest 1.1 installer is `AutoHotkey_1.1.37.02_setup.exe` on that page).
2. Make sure `Gdip_All.ahk` (see Dependencies above) is sitting in the same folder as `Anachrokey.ahk`.
3. Run the `.ahk` file directly, or compile your own exe with AutoHotKey — just make sure `Gdip_All.ahk` is present in the same directory at compile time so it gets baked into the output.

---

### How to activate automatically at startup (no need to click manually anymore)

1. Copy the Anachrokey.exe
2. Type: <kbd>⊞ Win</kbd> + <kbd>R</kbd>
3. Type: `shell:Common Start Menu`
4. Go to: `Programs\Startup`
5. Paste the script to that folder 

Now the script is automatically active at startup 

---

## Known limitations on initial release 

- `Win+V` and `Win+Shift+S` are still under active development — functional, but not yet as thoroughly tested across different XP configurations as the rest of the shortcuts. If something behaves oddly, it's most likely one of these two.
- The clipboard history only tracks plain text. Copied images and files aren't captured — this was a deliberate choice to keep it simple and avoid bloating memory with binary clipboard data.
- Window snapping is left/right halves only, no quarter-tiling like Windows 11's snap layouts. XP's window management model doesn't really lend itself to more than that without a lot of extra tracking code.
- "Peek Desktop" is a real minimize-and-restore, not the live transparent preview XP obviously can't render. It gets you the same result — see the desktop, get your windows back — just without the eye candy.
- The Quick Link menu (`Win+X`) is a plain right-click style menu, since XP doesn't have a Win8-style overlay to hook into.
- Multi-monitor window throwing only makes sense if you're actually running more than one monitor — on a single display it just does nothing, silently.

---

## Why AutoHotkey 1.1 and not v2

Compatibility with older systems, and the latest version of AutoHotKey does not support Windows XP. A lot of machines that are still running XP SP3 today are running it because of legacy hardware or legacy software dependencies, and pairing that with the newest AHK runtime felt like it defeated the point. AHK 1.1 is also far better documented for XP-era edge cases (window styles, `SendMessage`, GDI+ calls) since most of that documentation and community knowledge was written back when XP was still the dominant OS.

---

## Credits

- [Gdip_All.ahk](https://github.com/marius-sucan/AHK-GDIp-Library-Compilation/blob/master/ahk-v1-1%2FGdip_All.ahk) by tic (Tariq Porter), maintained/updated by marius-sucan — used here for screen capture.
- Everything else is original AutoHotkey code written for this project.

---

## License

Copyright © 2026 Marcel Stevano.

Released under the GNU General Public License v3.0. In short: you're free to use, study, modify, and redistribute this, but any derivative work you distribute has to stay under GPL-3.0 too and keep its source available. (The bundled `Gdip_All.ahk` keeps its own original license; that part isn't relicensed by this project's GPL-3.0 terms.)
