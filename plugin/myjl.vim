if exists('s:loaded') || has('nvim')
  finish
endif
let s:loaded = 1

call myjl#init()

" vi:set sts=2 sw=2 et:
