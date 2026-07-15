# vim-popclip

A Vim plugin that displays selected text in a popup window.

<img width="1146" height="653" alt="popclip" src="https://github.com/user-attachments/assets/a0ea3e2d-fe98-4855-88a1-220316c8af70" />

## Requirements

Vim9 script

## Installation

```vim
vim9script
packadd vim-popclip
popclip#Init({ key: 'C' })
```

## Usage

### Clip Visual Block

1. Enter Visual Block mode and select text.
2. Press `C`

Also, you can clip text-obj.

e.g.) Press `Ciw` in Normal Mode.

### Move Popup

1. Press `cC` to enter move mode.
2. Use `h`, `j`, `k`, `l` to move the popup window.
3. Press `<CR>` to confirm and exit.

If multiple popups are open:

- Move your cursor to focus on a target popup, or
- Input the specific `winid` to select it.

#### Move Mode Mappings

- `h` ... Left
- `j` ... Up
- `k` ... Down
- `l` ... Right
- `^` or `0` ... Left Edge
- `$` ... Right Edge
- `t` ... Top
- `b` ... Bottom
- `z` ... Increment z-index
- `Z` ... Decrement z-index
- `<CR>` or `<Esc>` ... Confirm and exit.

### Close Popup

Press `dC`

### Yank Popup Text

- Linewise: Press `yC` or `yaC`
- Blockwise: Press `yiC`

## Configuration

To customize the plugin, pass a dictionary of settings to `popclip#Init({settings})`.  
You only need to specify the options you want to change from the default values:

```vim
vim9script
# Example: Only changing the key mapping and clip_and_move option
popclip#Init({
  key: "\<Space>c",
  clip_and_move: true,
})
```

- `key` (String): Default `''`.  
  The base key mapping for the plugin.
- `move_label` (String): Default `'+'`.  
  The indicator label displayed on the popup window in move mode.
- `clip_and_move` (Boolean): Default `false`.  
  Automatically enter move mode immediately after displaying a popup.
- `yank_blockwise` (Boolean): Default `false`.  
  Changes the behavior of `yC` to yank as blockwise instead of linewise.
- `select_at_cursor` (Boolean): Default `true`.  
  Enables selecting a target popup based on the cursor position.
- `popup_props` (Dictionary):  
  Options passed directly to `popup_create()` arguments.

## Mappings

Use the following `<Plug>` mappings if you want manual control over your keybindings:

- `<Plug>(popclip-clip)`: nmap, xmap  
  Displays the selected text in a popup window.
- `<Plug>(popclip-op)`: omap  
  Triggers a sub-mode to yank, close, or move the popup window.
- `<Plug>(popclip-op-b)`: omap  
  Forces the popup text to be yanked as blockwise.
- `<Plug>(popclip-op-l)`: omap  
  Forces the popup text to be yanked as linewise.

## Functions

You can call the following functions to interact with the plugin:

- `popclip#Init({settings})`  
  Initializes the plugin with user configurations.  
  (See the Configuration section for details.)
- `popclip#PopupList()`  
  Return a List with the window-ID of all existing popclip popups.  
  Return type: `list<number>`

## License

[NYSL](http://www.kmonos.net/nysl/index.en.html) (c) utubo

