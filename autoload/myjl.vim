" 实现自己的 jumplist，位置是基于 bufnr, lnum, col, coladd 的，
" 只要此组合有意义，即认为是有效
" jump marks 是否相同，只比较 bufnr 和 lnum

if exists('s:loaded')
  finish
endif
let s:loaded = 1

let s:prev_winid = 0

function myjl#init()
  augroup myjl
    autocmd!
    autocmd CursorMoved * call myjl#onCursorMoved()
    autocmd BufEnter * call myjl#onCursorMoved()
    autocmd WinNew * call myjl#onWinNew()
    autocmd VimEnter * call myjl#onVimEnter()
  augroup END
  nnoremap <silent> <C-o> :call myjl#backward()<CR>
  nnoremap <silent> <C-i> :call myjl#forward()<CR>
  command! MyjlExit call myjl#exit()
  command! MyjlDump call myjl#dump(0)
  command! MyjlFresh call myjl#onWinNew()
  command! MyjlClear call myjl#clear()
endfunction

function myjl#exit()
  silent! augroup! myjl
  silent! nunmap <C-o>
  silent! nunmap <C-i>
  delcommand MyjlExit
  delcommand MyjlDump
  delcommand MyjlFresh
  delcommand MyjlClear
endfunction

" 跳转表仅有两种添加新项目的方式
"   - <C-o>       => 此时往回跳，把当前光标位置添加到最后
"   - <C-]> etc.  => 此时往前跳，把当前光标位置添加到最后
"
" 跳转表可能缩小的情形
"   - :clearjumps
"   - 修改文本后，自动修整 jumplist
"
" 此函数只处理前向跳转，以及由于文本改变导致 jumplist 删除
function myjl#onCursorMoved() abort
  let curr_jumplist = getjumplist()
  if !exists('w:prev_jumplist')
    call myjl#onWinNew()
  endif
  let prev_jumplist = w:prev_jumplist
  let w:prev_jumplist = curr_jumplist

  let prev_len = len(prev_jumplist[0])
  let curr_len = len(curr_jumplist[0])

  " BUG: 第二次获取，getjumplist()[1] 才是正确值
  if curr_jumplist[1] > curr_len
    let curr_jumplist[1] = curr_len
  endif

  if curr_len == 0
    return
  endif

  " 插入新条目的强特征:
  "   - getjumplist()[1] >= len(getjumplist()[0])
  " 不满足的话，直接 pass
  if !(curr_jumplist[1] >= len(curr_jumplist[0])) || empty(curr_jumplist[0])
    return
  endif

  if prev_len > curr_len
    " 可以确定是由于 TextChanged 导致 jumplist 修剪了
    return
  endif

  " 满足特征的话，需要判断 jumplist 是否修改，直接检查最后一项
  " NOTE: 不一定正确，例如 TextChanged 导致 jumplist 修剪
  if prev_len == curr_len
    if prev_jumplist[0][-1]['bufnr'] == curr_jumplist[0][-1]['bufnr'] &&
          \ prev_jumplist[0][-1]['lnum'] == curr_jumplist[0][-1]['lnum']
      return
    endif
  endif

  " @case 跳转到新位置，并且去除了重复的条目
  " @case TextChanged 导致最后一项条目修改了 FIXME: 这种情况无法完善处理
  call filter(w:myjl_jumplist, {idx, val -> idx <= w:myjl_jumplistidx})
  let entry = curr_jumplist[0][-1]
  let lasted = get(w:myjl_jumplist, -1, {})
  if entry['bufnr'] != get(lasted, 'bufnr')
        \ || entry['lnum'] != get(lasted, 'lnum')
    call add(w:myjl_jumplist, curr_jumplist[0][-1])
  endif
  " 当发生回跳时，添加这个条目
  let w:pend_entry = myjl#makeEntry()
  let w:myjl_jumplistidx = len(w:myjl_jumplist)
endfunction

" 创建新窗口时。不用于 Vim 启动时的首个窗口。在 WinEnter 事件之前激活。
function myjl#onWinNew()
  "echomsg 'enter WinNew'
  let w:prev_jumplist = getjumplist()
  let w:myjl_jumplist = w:prev_jumplist[0]
  let w:myjl_jumplistidx = len(w:myjl_jumplist)
  let w:pend_entry = {}   " 用于记忆最新的前向跳转位置
  let s:prev_winid = win_getid()
endfunction

function myjl#onVimEnter()
  "echomsg 'enter VimEnter'
  call myjl#onWinNew()
endfunction

function myjl#forward()
  if w:myjl_jumplistidx >= len(w:myjl_jumplist) - 1
    return
  endif
  let w:myjl_jumplistidx += 1
  call myjl#jump()
endfunction

function myjl#backward()
  let curr_jumplist = getjumplist()
  if curr_jumplist[1] >= len(curr_jumplist[0])
    if w:myjl_jumplistidx <= 0
      return
    endif
    call myjl#addEntry(w:pend_entry)
    let w:pend_entry = {}
    let w:myjl_jumplistidx -= 1
    execute "normal! \<C-o>"
  else
    if w:myjl_jumplistidx <= 0
      let w:myjl_jumplistidx = 0
      return
    endif
    let w:myjl_jumplistidx -= 1
    call myjl#jump()
  endif
endfunction

function myjl#jump()
  let pos = get(w:myjl_jumplist, w:myjl_jumplistidx)
  if bufexists(pos['bufnr'])
    execute 'keepjumps b' pos['bufnr']
    keepjumps call setpos('.', [0, pos['lnum'], pos['col'], pos['coladd']])
  endif
endfunction

" 显示调试信息
function myjl#dump(...)
  let result = [w:myjl_jumplist, w:myjl_jumplistidx]
  let silent = get(a:000, 0, 1)
  if !silent
    echo result
  endif
  return result
endfunction

function myjl#clear()
  let w:prev_jumplist = [[], 0]
  call filter(w:myjl_jumplist, 0)
  let w:myjl_jumplistidx = 0
  let w:pend_entry = {}
endfunction

" 返回 0 表示没有插入，当前 entry 为重复的
" 返回 1 表示插入成功
function myjl#addEntry(entry)
  let entry = a:entry
  let lasted = get(w:myjl_jumplist, -1, {})
  if entry['bufnr'] != get(lasted, 'bufnr')
        \ || entry['lnum'] != get(lasted, 'lnum')
    call add(w:myjl_jumplist, entry)
    return 1
  endif
  return 0
endfunction

function myjl#makeEntry()
  let curpos = getcurpos()
  let entry = {}
  let entry['bufnr'] = bufnr('%')
  let entry['lnum'] = curpos[1]
  let entry['col'] = curpos[2]
  let entry['coladd'] = curpos[3]
  return entry
endfunction

" vi:set sts=2 sw=2 et:
