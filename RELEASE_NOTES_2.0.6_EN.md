# AntiInspector 2.0.6

This update improves gem readability and completes the addon's client-language localization.

## What's changed

- Added quality-based colors to gem names in the **Gems** table:
  - Epic gems are shown in bright purple.
  - Rare gems are shown in blue.
  - Uncommon gems are shown in green.
  - Empty sockets are shown in red.
- Color is determined from the gem item's quality reported by the WoW client.
- Mixed items are supported: every gem in a cell keeps its own quality color, while an empty socket in the same item remains red.
- The Russian `ruRU` client now displays both the **Enchants** and **Gems** interfaces in Russian, including slot names, statuses, buttons, hints, and localized gem names.
- English clients display the complete addon interface in English.
- TSV export remains fully English and contains no WoW color codes, preserving reliable copy and paste into Microsoft Excel.

## Compatibility

- World of Warcraft 3.3.5a (Wrath of the Lich King)
- Parties and raids
- Addon version: `2.0.6`

After replacing the addon files, restart the game or run `/reload`.
