if exists('g:loaded_curfunc_sidebar_nvim') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_curfunc_sidebar_nvim = 1
