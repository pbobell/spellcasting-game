# Loading Data

To load ability data:

1. Click "Sync CSV Spreadsheets" at the bottom of the main game view window
2. A small panel will open immediately above it. Click "Sync Now"
   a. You can confirm it succeeded by checking that `abilities/Spellcaster-game Data - Abilities (exported).csv` reflects your changes, in an external editor
3. From the top menu bar, go to Project -> Tools -> SimpleCsvToResourceGodot
4. Ensure:
   - CSV path at the top is to `abilities/Spellcaster-game Data - Abilities (exported).csv`
   - In the upper right, the template "AbilityData" is selected
   - The row "Ability" has type "Name"
   - At the bottom, "Location to export to" is `abilities/`
   - At the bottom right, next to the (checked) "Gen Resources" box, the dropdown is "Replace Old"
5. Click Export
6. Close the window (it won't on its own, and is safe to X out of)

The new values from your spreadsheet should be reflected in the various `abilities/*.tres` files.

You should be able to open them by double-clicking them in the editor's lower-left file manager, and then you'll see them in the panel on the right. However, sometimes changes don't appear to be reflected there, and I don't know why. The underlying data appears to be correct, and you can manually inspect the `.tres` files to confirm.

These AbilityData resources will be used as inputs to game logic.
