" smartq.vim
" Version: 1.3
"
" Author:
"   Mark Lucernas <https://github.com/marklcrns>
" Date:
"   2021-06-12
" Licence:
"   MIT

let s:save_cpo = &cpo
set cpo&vim

" Global variables
if !exists('g:smartq_exclude_filetypes')
  let g:smartq_exclude_filetypes = [
        \ 'fugitive'
        \ ]
endif

if !exists('g:smartq_exclude_buftypes')
  let g:smartq_exclude_buftypes= [
        \ ''
        \ ]
endif

if !exists('g:smartq_q_filetypes')
  let g:smartq_q_filetypes = [
        \ 'diff', 'git', 'gina-status', 'gina-commit', 'snippets',
        \ 'floaterm'
        \ ]
endif

if !exists('g:smartq_q_buftypes')
  let g:smartq_q_buftypes = [
        \ 'quickfix', 'nofile'
        \ ]
endif

if !exists('g:smartq_bw_filetypes')
  let g:smartq_bw_filetypes = [
        \ ''
        \ ]
endif

if !exists('g:smartq_bw_buftypes')
  let g:smartq_bw_buftypes = [
        \ ''
        \ ]
endif

if !exists('g:smartq_auto_wipe_emtpy')
  let g:smartq_auto_wipe_emtpy = 1
endif

if !exists('g:smartq_no_exit')
  let g:smartq_no_exit = 0
endif

if !exists('g:smartq_auto_close_splits')
  let g:smartq_auto_close_splits = 0
endif

if !exists('g:smartq_goyo_integration')
  let g:smartq_goyo_integration = 1
endif

if !exists('g:smartq_zenmode_integration')
  let g:smartq_zenmode_integration = 1
endif

" SmartQ commands
if !exists(':SmartQ')
  command! -bang -complete=buffer -nargs=? SmartQ
        \ call smartq#smartq(<q-bang>, <q-args>, v:false)
endif

if !exists(':SmartQSave')
  command! -bang -complete=buffer -nargs=? SmartQSave
        \ call smartq#smartq(<q-bang>, <q-args>, v:true)
endif

if !exists('SmartQWipeEmpty')
  command! -bang -nargs=0 SmartQWipeEmpty
        \ call smartq#wipe_empty_bufs(<q-bang>)
endif

if !exists('SmartQCloseSplits')
  command! -nargs=0 SmartQCloseSplits call smartq#close_mod_splits('!')
endif


" Default mappings
nnoremap <silent>   <Plug>(smartq_this)               :<C-u>SmartQ<CR>
nnoremap <silent>   <Plug>(smartq_this_save)          :<C-u>SmartQSave<CR>
nnoremap <silent>   <Plug>(smartq_this_force)         :<C-u>SmartQ!<CR>
nnoremap <silent>   <Plug>(smartq_wipe_empty)         :<C-u>SmartQWipeEmpty<CR>
nnoremap <silent>   <Plug>(smartq_wipe_empty_force)   :<C-u>SmartQWipeEmpty!<CR>
nnoremap <silent>   <Plug>(smartq_close_splits)       :<C-u>SmartQCloseSplits<CR>

if get(g:, 'smartq_default_mappings', 1) ==# 1
  " Remap macro record to Q
  nnoremap Q q
  nmap q        <Plug>(smartq_this)
  nmap <C-q>    <Plug>(smartq_this_force)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
