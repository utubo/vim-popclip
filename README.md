# vim-popclip

<img width="1146" height="653" alt="popclip" src="https://github.com/user-attachments/assets/a0ea3e2d-fe98-4855-88a1-220316c8af70" />

# Usage

```vim
vim9script
packadd vim-popclip
popclip#Init({ key: 'P' })
```

## Clip Visual Bock

1. Select a visual block
2. type 'P'

Also, you can clip text-obj.

e.g.) type 'Piw' on Normal Mode.

## Move Popup

1. type 'cP'
2. type 'h', 'j', 'k', 'l' to move the popup.
3. type '<CR>' to complete.

If the clips are popuped more than 1,
You can move the cursor or input the winid to select the target popup.

## Close Popup

type 'dP'

## Yank Cliped Text

- As Text block: type 'yP' or 'yiP'
- As Lines: type 'yaP'

# Settings
popclip#Init(&lt;settings>)

- key: Default ''. Mapping key.
- move_label: Default '+', The label of a moving popup window.
- clip_and_move: Default false, Move the popup after clip a text.
- yank_block: Default false, Yank the cliped text as lines with type 'yP'.   
- select_at_cursor: Default true, Enable select target popup at the cursor.
- popup_props: popup_create-aguments.


