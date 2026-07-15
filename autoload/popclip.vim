vim9script

# Settings and Utils {{{
g:popclip = {
  key: '',
  move_label: '+',
  clip_and_move: false,
  yank_blockwise: false,
  select_at_cursor: true,
  popup_props: {
    border: [1, 1, 1, 1],
  },
}->extend(get(g:, 'popclip', {}))

export def Init(settings: dict<any>)
  g:popclip = g:popclip->extend(settings)
  Map(g:popclip.key)
enddef

export def PopupList(): list<number>
  return popup_list()
    ->filter((_, id) => getwinvar(id, 'is_popclip', false))
enddef

def GetBdWidth(idx: number): number
  try
    return g:popclip.popup_props.border[idx]
  catch
    return 0
  endtry
enddef
# }}}

# Clip {{{
export def Clip(motion: string = '')
  # Clip selected text
  var head = getpos("'[")
  var tail = getpos("']")
  var pos = screenpos(0, head[1], head[2])
  var text = []
  if motion ==# 'block'
    normal! gv
    tail[2] = max([tail[2], getcurpos()[4]])
    const rx1 = $'\%{tail[2]}c.*'
    const rx2 = $'\%{head[2]}c.*'
    for l in range(head[1], tail[1])
      text->add(getline(l)->substitute(rx1, '', '')->matchstr(rx2))
    endfor
    feedkeys("\<Esc>")
  elseif motion ==# 'char'
    text = getregion(head, tail, { type: 'v' })
    if head[1] !=# tail[1]
      const left = screenpos(0, head[1], 1)
      text[0] = repeat(' ', pos.col - left.col + 1) .. text[0]
      pos.col = 1
    endif
  else
    text = getline(head[1], tail[1])
  endif
  const id = popup_create(text, {
    line: max([1, pos.row - GetBdWidth(0)]),
    col: max([1, pos.col - GetBdWidth(3)]),
  }->extend(g:popclip.popup_props))
  setwinvar(id, 'is_popclip', true)

  # Fix syntax highlights
  var l = 1
  var c = 1
  var hl = 'Normal'
  while true
    const ll = head[1] + l - 1
    const cc = (motion ==# 'block' || l ==# 1 ? head[2] : 1) + c - 1
    if tail[1] < ll || tail[1] ==# ll && tail[2] < cc
      break
    endif
    hl = synID(ll, cc, 1)->synIDattr('name') ?? hl
    win_execute(id, $"call matchaddpos('{hl}', [[{l}, {c}]])")
    c += 1
    if motion ==# 'block' && tail[2] <= cc || getline(ll)->len() < cc
      l += 1
      c = 1
    endif
  endwhile

  if g:popclip.clip_and_move
    timer_start(1, (_) => {
      Move([id])
    })
  endif
enddef
# }}}

# Move Popup windows {{{
var moveids = []
var movecount = 0

export def Move(ids: list<number>)
  moveids = ids
  for w in moveids
    popup_setoptions(w, { title: g:popclip.move_label })
  endfor
  # NOTE: <Esc> to exit Insert mode
  feedkeys("\<Esc>\<ScriptCmd>call popclip#KeyhookForMove()\<CR>", 'n')
enddef

export def KeyhookForMove()
  popup_create('', {
    filter: MoveFilter,
    mapping: false,
    line: &lines,
    col: &columns,
    highlight: 'MsgArea',
    opacity: 0,
  })
enddef

def MoveFilter(popupid: number, k: string): bool
  const mc = movecount ?? 1
  var dx = 0
  var dy = 0
  var dz = 0
  if k ==# ' ' || k ==# "\<CR>" || k ==# "\<Esc>"
    for _id in moveids
      popup_setoptions(_id, { title: '' })
    endfor
    popup_close(popupid)
  elseif k ==# 'j'
    dy = mc
  elseif k ==# 'l'
    dx = mc
  elseif k ==# 'k'
    dy = - mc
  elseif k ==# 'h'
    dx = - mc
  elseif k ==# 'b'
    dy = &lines
  elseif k ==# '$'
    dx = &columns
  elseif k ==# 't'
    dy = - &lines
  elseif k ==# '^' || k ==# '0' && movecount ==# 0
    dx = - &columns
  elseif k ==# 'z'
    dz = mc
  elseif k ==# 'Z'
    dz = - mc
  elseif k =~# '[0-9]'
    movecount = movecount * 10 + str2nr(k)
  else
    return false
  endif
  if dx !=# 0 || dy !=# 0 || dz !=# 0
    for id in moveids
      const p = popup_getpos(id)
      if dx !=# 0
        popup_move(id, { col: max([1, min([p.col + dx, &columns])]) })
      elseif dy !=# 0
        popup_move(id, { line: max([1, min([p.line + dy, &lines])]) })
      elseif dz !=# 0
        const z = popup_getoptions(id)->get('zindex', 50) + dz
        popup_setoptions(id, { zindex: max([0, min([z, 32000])]) })
      endif
    endfor
    movecount = 0
  endif
  return true
enddef
# }}}

# Input prompt for operation targets {{{
var popupids = []

export def Completion(a: any, c: any,  p: any): list<string>
  var l = []
  for id in popupids
    l->add($'{id}')
  endfor
  return l
enddef

def GetWinid(): list<number>
  if g:popclip.select_at_cursor
    const cur = getcurpos()
    const scr = screenpos(cur[0], cur[1], cur[2])
    var id = popup_locate(scr.row, scr.col)
    if !!id && getwinvar(id, 'is_popclip', false)
      return [id]
    endif
  endif
  var targets = []
  popupids = PopupList()
  if popupids->len() ==# 0
  # NOP
  elseif popupids->len() ==# 1
    targets = popupids
  else
    try
      for id in popupids
        popup_setoptions(id, { title: $'{id}' })
      endfor
      redraw
      const ids = input('winid: ', '', 'customlist,popclip#Completion')
      if ids ==# '*'
        targets = popupids
      else
        for id in ids->split('[^0-9]\+')
          targets->add(id->str2nr())
        endfor
      endif
    finally
      for id in popupids
        popup_setoptions(id, { title: '' })
      endfor
      redraw
    endtry
  endif
  if !!targets && !targets[0]
    echoh WarningMsg
    echo 'Bad id.'
    echoh MsgArea
    return []
  endif
  return targets
enddef
# }}}

# Operations {{{
var yankopt = ''
var yankreg = ''
var yanklines: any = ''

export def Op(ope: string, reg: string, wise: string = '')
  const ids = GetWinid()
  if !ids
    return
  endif
  if ope ==# 'c'
    Move(ids)
    return
  endif
  if ope ==# 'y' || ope ==# 'd'
    yankopt = !wise ? g:popclip.yank_blockwise ? 'b' : 'l' : wise
    yankreg = reg
    yanklines = []
    for i in ids
      yanklines += winbufnr(i)->getbufline(1, '$')
    endfor
    au SafeState * ++once setreg(yankreg, yanklines->join("\n"), yankopt)
  endif
  if ope ==# 'd'
    for id in ids
      popup_close(id)
    endfor
  endif
enddef
# }}}

# Mapping {{{
nnoremap <silent> <Plug>(popclip-clip) <ScriptCmd>&opfunc = 'popclip#Clip'<CR>g@
xnoremap <silent> <Plug>(popclip-clip) <ScriptCmd>&opfunc = 'popclip#Clip'<CR>g@
onoremap <silent> <Plug>(popclip-op)   <ScriptCmd>popclip#Op(v:operator, v:register)<CR>
onoremap <silent> <Plug>(popclip-op-b) <ScriptCmd>popclip#Op(v:operator, v:register, 'b')<CR>
onoremap <silent> <Plug>(popclip-op-l) <ScriptCmd>popclip#Op(v:operator, v:register, 'l')<CR>

def Map(key: string)
  if !key
    return
  endif
  const k = key->keytrans()
  execute $'nmap {k} <Plug>(popclip-clip)'
  execute $'xmap {k} <Plug>(popclip-clip)'
  execute $'omap {k} <Plug>(popclip-op)'
  execute $'omap i{k} <Plug>(popclip-op-b)'
  execute $'omap a{k} <Plug>(popclip-op-l)'
  execute $'nmap {k}{key[-1]->keytrans()} 0<Plug>(popclip)$'
enddef
# }}}

