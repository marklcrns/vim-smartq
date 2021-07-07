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
        \ 'quickfix', 'terminal', 'nofile'
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


" SmartQ commands
if !exists(':SmartQ')
  command! -bang -complete=buffer -nargs=? SmartQ
        \ call smartq#smartq(<q-bang>, <q-args>)
endif

if !exists('SmartQWipeEmpty')
  command! -bang -nargs=0 SmartQWipeEmpty
        \ call smartq#wipe_empty_bufs(<q-bang>)
endif

if !exists('SmartQCloseSplits')
  command! -nargs=0 SmartQCloseSplits call smartq#close_mod_splits()
endif


" Default mappings
nnoremap <silent>   <Plug>(smartq_this)               :<C-u>SmartQ<CR>
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
