# AntiInspector 2.0.7

This release introduces a new moonkin-themed window background and makes gem information substantially more useful and readable.

## What's changed

### New background and appearance settings

- Added an original dark, moonlit forest background with a small aggressive moonkin in the lower-right corner.
- Added a saved **Background** slider from 0% to 100%:
  - `0%` makes the artwork fully transparent.
  - `100%` makes the artwork fully opaque.
- The window border, controls, table text, and export window are not affected by background opacity.
- The artwork uses a power-of-two, uncompressed 32-bit TGA texture for reliable WoW 3.3.5a client compatibility.
- The texture now has a unique extensionless addon path so the client does not reuse a previously rejected cached image.

### More useful gem information

- The **Gems** table now displays localized stat effects such as `+20 Strength` or `+20 к силе` instead of gem item names.
- Gem effects are read from the game tooltip in the active client language.
- Different effects are displayed on separate lines.
- Duplicate effects on one item are grouped into compact values such as `+20 Strength x3`.
- Existing gem-quality colors remain available:
  - Epic — bright purple.
  - Rare — blue.
  - Uncommon — green.
  - Empty socket — red.

### Adjustable equipment-cell font

- Added a saved **Cell font** slider with a deliberately readable range from 8 to 11 points.
- The setting applies immediately to equipment cells on both the **Enchants** and **Gems** tabs.
- The default cell font size is 9 points.
- Equipment-cell text uses an outline for improved readability over the background.
- Table rows are slightly taller to accommodate multi-line gem effects.

### Localization and export

- Russian clients display both settings and their tooltips in Russian.
- English clients display both settings and their tooltips in English.
- TSV and Excel exports remain fully English and contain no UI color codes.

## Compatibility

- World of Warcraft 3.3.5a (Wrath of the Lich King)
- Parties and raids
- Addon version: `2.0.7`

After replacing the addon files, fully exit WoW and start it again. A `/reload`
alone may not load the newly named texture on legacy clients.
