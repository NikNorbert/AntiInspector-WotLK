<div align="center">

# AntiInspector

**Manual enchant and gem auditing for parties and raids in World of Warcraft 3.3.5a**

Find missing enchants and empty sockets, rescan individual players,<br>
and move the results into Excel — all from one window.

<p>
  <img src="https://img.shields.io/badge/WoW-3.3.5a%20WotLK-C79C6E?style=flat-square" alt="WoW 3.3.5a WotLK">
  <img src="https://img.shields.io/badge/Interface-30300-4B69FF?style=flat-square" alt="Interface 30300">
  <img src="https://img.shields.io/badge/Version-2.0.7-A335EE?style=flat-square" alt="Version 2.0.7">
  <img src="https://img.shields.io/badge/UI-EN%20%2F%20RU-1EFF00?style=flat-square" alt="English and Russian UI">
</p>

<p>
  <a href="https://github.com/NikNorbert/AntiInspector-WotLK/archive/refs/tags/v2.0.7.zip"><img src="https://img.shields.io/badge/DOWNLOAD-v2.0.7-A335EE?style=for-the-badge&amp;logo=github" alt="Download AntiInspector 2.0.7"></a>
  <a href="RELEASE_NOTES_2.0.7_EN.md"><img src="https://img.shields.io/badge/RELEASE%20NOTES-2.0.7-C79C6E?style=for-the-badge&amp;logo=readme" alt="Read the AntiInspector 2.0.7 release notes"></a>
</p>

[Русская документация](README_RU.md) · [Detailed English documentation](README_EN.md)

</div>

![AntiInspector enchant audit](Screenshots/1_srn.jpg)

## Highlights

| Audit | Workflow | Export |
| --- | --- | --- |
| Enchants, gems, and empty sockets | Parties and raids | Excel-compatible TSV |
| Class and active talent build | Rescan a player by clicking their name | Optional `.tsv` and `.xlsx` creation |
| Buckle and profession bonus sockets | Minimap button and slash commands | Consistent English report values |

- Separate **Enchants** and **Gems** tabs with clear color-coded results.
- The most recent scan is preserved across `/reload` and game sessions.
- Russian UI is selected automatically on `ruRU`; other clients use English.
- Table font size and background opacity can be adjusted and are saved.
- Scans run only when requested and use the standard WoW Inspect API.

## Quick start

1. Click **DOWNLOAD v2.0.7** above, or [download the current `main` branch](https://github.com/NikNorbert/AntiInspector-WotLK/archive/refs/heads/main.zip).
2. Extract the archive, rename the extracted folder to `AntiInspector`, and place it in:

   ```text
   World of Warcraft\Interface\AddOns\AntiInspector\
   ```

3. Confirm that the addon file is located at:

   ```text
   World of Warcraft\Interface\AddOns\AntiInspector\AntiInspector.toc
   ```

4. Fully restart the game. On first installation, `/reload` alone may not be enough because the 3.3.5a client can cache rejected textures.
5. Join a party or raid, leave combat, and enter `/ai` or click the AntiInspector minimap button.

> Other characters must be online, visible to the client, and nearby — approximately within 30 yards — to be inspected.

## Commands

| Command | Action |
| --- | --- |
| `/enchinsp` or `/ai` | Start a party or raid scan |
| `/enchinsp scan` | Start or restart a scan |
| `/enchinsp show` | Show the most recently saved table |
| `/enchinsp stop` | Stop the current scan |
| `/enchinsp export` | Open and select the TSV export text |
| `/enchinsp clear` | Delete the saved results |

Aliases `/antiinspector`, `/rea`, and `/raidcheck` are also supported.

## How scanning works

WoW 3.3.5a can inspect only one player at a time, so scanning a full raid takes a little while. AntiInspector reports a separate result for each character, such as **Ready**, **Out of range**, **Offline**, **No response**, or **No data**.

After the group scan finishes, click any character name in the table to inspect only that player again. Individual rescans also require the player to be outside combat and within Inspect range.

### Color legend

| Tab | Green | Yellow | Red | Gray `—` |
| --- | --- | --- | --- | --- |
| **Enchants** | A permanent enchant was found | — | A normally enchanted slot is missing its enchant | The slot is unavailable or does not normally require an enchant |
| **Gems** | Every detected socket is filled | Only some sockets are filled | All detected sockets are empty | The item has no sockets or the slot is unavailable |

## Exporting to Excel

1. Wait for the scan to finish and open the **Enchants** or **Gems** tab.
2. Click **Export TSV** or enter `/enchinsp export`.
3. Press `Ctrl+A`, then `Ctrl+C` in the export window.
4. Select cell `A1` in Excel and press `Ctrl+V`.

For automatic file creation, run `Start_AntiInspector_Excel_Export.cmd` before copying the export. The Windows helper monitors only clipboard text and saves the result in:

```text
World of Warcraft\AntiInspector_Exports\
```

When Microsoft Excel is installed, the helper creates both `.tsv` and `.xlsx` files. Without Excel, it still creates a UTF-8 `.tsv` file.

## Screenshots

<table>
  <tr>
    <td align="center"><strong>Gems and empty sockets</strong></td>
    <td align="center"><strong>TSV export</strong></td>
  </tr>
  <tr>
    <td><a href="Screenshots/2_srn.jpg"><img src="Screenshots/2_srn.jpg" alt="AntiInspector gem audit"></a></td>
    <td><a href="Screenshots/3_srn.jpg"><img src="Screenshots/3_srn.jpg" alt="AntiInspector TSV export"></a></td>
  </tr>
</table>

## Compatibility and limitations

- **World of Warcraft:** 3.3.5a (Wrath of the Lich King)
- **Interface:** `30300`
- **Addon version:** `2.0.7`
- Inspect results depend on distance, visibility, server behavior, and item data cached by the client.
- AntiInspector reports installed upgrades; it does not calculate stat caps or decide the best enchant or gem for a particular build.

More: [detailed documentation](README_EN.md) · [release notes 2.0.7](RELEASE_NOTES_2.0.7_EN.md) · [report an issue](https://github.com/NikNorbert/AntiInspector-WotLK/issues)

<div align="center">

Made by Guild **CEKTA** with ❤️

</div>
