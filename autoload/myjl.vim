" 实现自己的 jumplist，位置是基于 bufnr, lnum, col, coladd 的，
" 只要此组合有意义，即认为是有效
" jump marks 是否相同，只比较 bufnr 和 lnum

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
  nnoremap <C-o> <C-o>:call myjl#on_new_jumplist_entry_backward()<CR>
endfunction

function myjl#exit()
  silent! augroup! myjl
  silent! nunmap <C-o>
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
  let prev_jumplist = s:prev_jumplist
  let s:prev_jumplist = curr_jumplist

  let prev_len = len(prev_jumplist[0])
  let curr_len = len(curr_jumplist[0])

  " BUG: 第二次获取，getjumplist()[1] 才是正确值
  if curr_jumplist[1] > curr_len
    let curr_jumplist[1] = curr_len
  endif

  if curr_len == 0
    call filter(s:jumplist_flags, 0)
    return
  endif

  " 插入新条目的强特征:
  "   - (getjumplist()[1] >= len(getjumplist()[0])
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
  " @case TextChanged 导致最后一项条目修改了
  call filter(s:myjl_jumplist, {idx, val -> idx < s:myjl_jumplistidx})
  call add(s:myjl_jumplist, curr_jumplist[0][-1])
  let s:myjl_jumplistidx = len(s:myjl_jumplist)
endfunction

" 创建新窗口时。不用于 Vim 启动时的首个窗口。在 WinEnter 事件之前激活。
function myjl#onWinNew()
  "echomsg 'enter WinNew'
  let s:myjl_jumplist = getjumplist()[0]
  let s:myjl_jumplistidx = len(s:myjl_jumplist)
endfunction

function myjl#onVimEnter()
  "echomsg 'enter VimEnter'
  let s:myjl_jumplist = getjumplist()[0]
  let s:myjl_jumplistidx = len(s:myjl_jumplist)
endfunction

function myjl#on_new_jumplist_entry_backward()
  let curr_jumplist = getjumplist()
  if curr_jumplist[1] + 2 == len(curr_jumplist[0])
    call add(s:myjl_jumplist, curr_jumplist[0][-1])
  endif
endfunction

" 显示调试信息
function myjl#dump()
  echo s:myjl_jumplist
  echo s:myjl_jumplistidx
  return s:myjl_jumplist
endfunction

function myjl#clear()
  let s:myjl_jumplistidx = 0
  call filter(s:myjl_jumplist, 0)
endfunction

" vi:set sts=2 sw=2 et:
