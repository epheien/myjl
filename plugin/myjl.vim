if exists('s:loaded') || !exists('*getjumplist')
  finish
endif
let s:loaded = 1

" 一个新跳转发生的时候，是否保存这个新跳转的目的地
" NOTE: 实现有缺陷，也很难实现，暂时使用最简单粗暴的方法就好了
let g:myjl_save_forward = 0

command MyjlInit call myjl#init()
if get(g:, 'myjl_enable', 1)
  call myjl#init()
endif

" vi:set sts=2 sw=2 et:
