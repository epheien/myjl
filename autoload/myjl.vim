if exists('s:loaded')
  finish
endif
let s:loaded = 1

" winid => w:myjl
let s:myjl = {}
let s:prev_curpos = []
let s:prev_jumplist = [[], -1]
" 0 表示无效，1 表示有效
let s:jumplist_flags = []

function myjl#init()
  augroup myjl
    autocmd CursorMoved * call myjl#onCursorMoved()
    autocmd WinNew * call myjl#onWinNew()
    autocmd VimEnter * call myjl#onVimEnter()
  augroup END
  nnoremap <C-o> :call myjl#on_new_jumplist_entry_backward()<CR><C-o>
endfunction

function myjl#exit()
  augroup! myjl
endfunction

function myjl#onCursorMoved() abort
  " 跳转表仅有两种添加新项目的方式
  "   - <C-o>       => 此时往回跳，把当前光标位置添加到最后
  "   - <C-]> etc.  => 此时往前跳，把当前光标位置添加到最后
  let curr_jumplist = getjumplist()
  if get(s:prev_jumplist[0], -1, {}) == get(curr_jumplist[0], -1, {})
    let s:prev_jumplist = curr_jumplist
    return
  endif

  " 去除多余的 s:jumplist_flags
  if len(s:jumplist_flags) > len(curr_jumplist[0])
    if empty(curr_jumplist[0])
      "call filter(s:jumplist_flags, 0)
      let s:jumplist_flags = []
    else
      let s:jumplist_flags = s:jumplist_flags[-len(curr_jumplist[0]):-1]
    endif
  endif

  " (getjumplist()[1] >= len(getjumplist()[0]) => 插入新条目
  if !(curr_jumplist[1] >= len(curr_jumplist[0])) || empty(curr_jumplist[0])
    let s:prev_jumplist = curr_jumplist
    return
  endif

  " 前向添加跳转表
  call myjl#on_new_jumplist_entry(s:prev_jumplist[1], curr_jumplist[1])

  let s:prev_jumplist = curr_jumplist
endfunction

" 创建新窗口时。不用于 Vim 启动时的首个窗口。在 WinEnter 事件之前激活。
function myjl#onWinNew()
  "echomsg 'enter WinNew'
  let s:prev_jumplist = getjumplist()
  let s:myjl[win_getid(winnr())] = s:prev_jumplist
  let s:jumplist_flags = repeat([1], len(s:prev_jumplist[0]))
endfunction

function myjl#onVimEnter()
  "echomsg 'enter VimEnter'
  let s:prev_jumplist = getjumplist()
  " BUG: s:myjl[idx][1] == 100 !
  let s:myjl[win_getid(winnr())] = s:prev_jumplist
  let s:jumplist_flags = repeat([1], len(s:prev_jumplist[0]))
endfunction

function myjl#trim_jumplist_entry(jumplist, index)
endfunction

function myjl#on_new_jumplist_entry_backward()
  let curr_jumplist = getjumplist()
  if curr_jumplist[1] >= len(curr_jumplist[0]) && !empty(curr_jumplist[0])
    call add(s:jumplist_flags, 1)
  endif
endfunction

" 在添加新的jumplist entry之前，删除此之后的所有entry
"
" 如果你用跳转命令，当前的行号被插到跳转表的最后。如果相同的行已经在跳转表里，那
" 会被删除。结果是，CTRL-O 就会直接回到该行之前的位置。
"
"    jump line  col file/text
" 0    2	  1    0 some text
" 1    1	 70    0 another line
" 2 >  0  1154   23 end.
" 3    1  1167    0 foo bar
" =>
"    jump line  col file/text
" 0    4	  1    0 一些文字
" 1    3	 70    0 另外一行
" 2    2  1167    0 foo bar
" 3    1  1154   23 end.
" 4 >
"
function myjl#on_new_jumplist_entry(prev_index, curr_index) abort
  " 假设没有重复项目，需要禁用 [prev_index + 1 : (curr_index - 2)] 的条目
  call add(s:jumplist_flags, 1)
  let sidx = a:prev_index + 1
  let eidx = a:curr_index - 2
  if eidx - sidx < -1
    return
  endif
  for idx in range(sidx, eidx)
    let s:jumplist_flags[idx] = 0
  endfor
endfunction

" 显示调试信息
function myjl#dump()
  "echo s:myjl
  echo s:prev_jumplist
  echo s:jumplist_flags
  return s:myjl
endfunction

" vi:set sts=2 sw=2 et:
