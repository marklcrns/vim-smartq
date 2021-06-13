let s:save_cpo = &cpo
set cpo&vim

" Excluded filetypes to disable SmartQ and to preserve windows when closing
" splits on excluded buffers. Non-modifiable are preserved by default.
let g:smartq_exclude_filetypes = [
      \ 'Mundo', 'MundoDiff', 'fugitive'
      \ ]
" Delete buffers using :bd command. Default for unspecified filetypes
let g:smartq_bd_filetypes = [
      \ 'git', 'gina-', 'qf'
      \ ]
" Wipe buffers using :bw command. Wiped buffers are removed from jumplist
let g:smartq_bw_filetypes = [
      \ ''
      \ ]
" Quit buffers using :q command. Non-modifiable and readonly file uses :q
let g:smartq_q_filetypes = [
      \ 'gitcommit'
      \ ]

command! -nargs=0 SmartQ            call smartq#smartq()
command! -nargs=0 SmartQCloseSplits call smartq#close_all_modifiable_splits()
command! -nargs=0 SmartQWipeEmpty   call smartq#wipe_empty_buffers()

nnoremap <silent>   <Plug>(smartq_smartq)         :<C-u>call smartq#smartq()<CR>
nnoremap <silent>   <Plug>(smartq_close_splits)   :<C-u>call smartq#close_all_modifiable_splits()<CR>
nnoremap <silent>   <Plug>(smartq_wipe_empty)     :<C-u>call smartq#wipe_empty_buffers()<CR>

if get(g:, 'smartq_default_mappings', 1) ==# 1
  " Remap macro record to Q
  nnoremap Q q
  nmap q  <Plug>(smartq_smartq)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
