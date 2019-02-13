# myjl

My own jumplist plugin for vim.

This plugin is my attempt for implement a web browser like jumplist.

## Install
```viml
Plug 'epheien/myjl'
```

## Usage

This plugin map `<C-o>` and `<C-i>` for jump and hook `VimEnter`, `WinNew`,
`CursorMove` events for refresh jumplist.

Vim inner jumplist is always available, but can not use `<C-o>` and `<C-i>` to
jump because they had been map by this plugin.

## Commands
  - `MyjlInit`
  - `MyjlExit`
  - `MyjlFresh` - Init myjl jumplist from vim inner jumplist of current window
  - `MyjlClear` - Clear myjl jumplist of current window
  - `MyjlDump`  - For debug, dump myjl jumplist info

## Options
  - `g:myjl_enable`, default `1`, if `0`, myjl will not auto active.

