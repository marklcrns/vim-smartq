let s:save_cpo = &cpo
set cpo&vim

" Excluded filetypes to disable SmartQ and to preserve windows when closing
" splits on excluded buffers. Non-modifiable are preserved by default.
if !exists('g:smartq_exclude_filetypes')
  let g:smartq_exclude_filetypes = [
        \ 'Mundo', 'MundoDiff', 'fugitive'
        \ ]
endif

" Delete buffers using :bd command. Default for unspecified filetypes
if !exists('g:smartq_bd_filetypes')
  let g:smartq_bd_filetypes = [
        \ 'git', 'gina-', 'qf'
        \ ]
endif

" Wipe buffers using :bw command. Wiped buffers are removed from jumplist
if !exists('g:smartq_bw_filetypes')
  let g:smartq_bw_filetypes = [
        \ ''
        \ ]
endif

" Quit buffers using :q command. Non-modifiable and readonly file uses :q
if !exists('g:smartq_q_filetypes')
  let g:smartq_q_filetypes = [
        \ 'gitcommit'
        \ ]
endif

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
