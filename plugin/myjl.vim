if exists('s:loaded') || !exists('*getjumplist')
  finish
endif
let s:loaded = 1

command MyjlInit call myjl#init()
if get(g:, 'myjl_enable', 1)
  call myjl#init()
endif

" vi:set sts=2 sw=2 et:
