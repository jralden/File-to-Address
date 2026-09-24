# File-to-Address

A macOS menu bar app that reads the file selected in Finder and types its full path at the cursor in the frontmost app. It is built for dropping screenshot paths into LLM prompts, such as Cursor chat.

## Use

1. Select one or more files in Finder (a window or the Desktop).
2. Click into the text field where the path should go.
3. Press **⌃⌥⌘V**, or choose **Insert Finder Selection Path** from the menu bar icon.

Paths that contain spaces are wrapped in double quotes. Multiple paths are separated by spaces. **Copy Finder Selection Path** puts the text on the clipboard without pasting it.

The app pastes the text, then restores whatever was on the clipboard before.

## Permissions

- **Accessibility** — needed to paste at the cursor. macOS prompts for it on first launch (System Settings › Privacy & Security › Accessibility).
- **Automation › Finder** — needed to read the Finder selection. macOS prompts the first time the app asks Finder.

## Build and install

```sh
scripts/build-app.sh            # builds build/File to Address.app
scripts/build-app.sh --install  # also copies it to /Applications and launches it
swift test                      # runs the unit tests
```

The script signs with the first Developer ID or Apple Development identity in the keychain, so permissions survive rebuilds. Set `SIGN_IDENTITY` to override it.

## Staying running

The app registers a launchd agent the first time it runs. The agent starts the app at login and relaunches it within about 10 seconds if it crashes. Choosing **Quit** from the menu stops it until the next login. Turn off **Launch at Login** in the menu to remove the agent. You can approve or remove it in System Settings › General › Login Items.
