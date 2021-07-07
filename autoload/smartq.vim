" smartq.vim
" Version: 1.1
"
" Description:
"   Sensibly close buffers with respect to alternate tabs and window splits,
"   and other types of buffer.
" Features:
"   - Delete buffers with preserving tabs and window splits displaying the same
"     buffer to be deleted.
"   - Keep tabs and window splits open with an empty buffer if pointing to
"     same buffer to be deleted.
"   - Prevents from deleting buffer if modified or in g:smartq_exclude_filetypes
"     and g:smartq_exclude_buftypes
"   - Handles diff splits, closing all diff buffer windows automatically.
"   - Goyo integration. Remain in Goyo tab when deleting buffers. Exists if only
"     one buffer remains.
" Commands:
"   :SmartQ
"   :SmartQ!
"   :SmartQCloseSplits
"   :SmartQWipeEmpty
"
" Author:
"   Mark Lucernas <https://github.com/marklcrns>
" Date:
"   2021-06-12
" Licence:
"   MIT
"
" Credits:
"   smartq#smartq()
"     - https://github.com/cespare/vim-sbd
"     - https://github.com/Asheq/close-buffers.vim
"     - https://stackoverflow.com/a/29236158
"     - https://superuser.com/questions/345520/vim-number-of-total-buffers
"   smartq#wipe_empty_buffers()
"     - https://stackoverflow.com/a/10102604
"   s:new_tmp_buf() and s:str_to_bufnr()
"     - https://github.com/moll/vim-bbye/blob/master/plugin/bbye.vim

if exists('g:smartq_loaded')
  finish
endif
let g:smartq_loaded = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:shift_win_buf_pointing_to_cur_buf(buffer)
  for i in range(1, tabpagenr('$'))
    silent execute 'tabnext ' . i
    if winnr('$') ># 1
      " Store active window nr to restore later
      let curWin = winnr()
      " Loop over windows pointing to curBuf
      let winnr = bufwinnr(a:buffer)
      while (winnr >= 0)
        " Go to window and switch to next buffer
        silent execute winnr . 'wincmd w | bnext'
        " Restore active window
        silent execute curWin . 'wincmd w'
        let winnr = bufwinnr(a:buffer)
      endwhile
    endif
  endfor
endfunction


function! s:str_to_bufnr(buffer)
  if empty(a:buffer)                " Current buffer
    return bufnr("%")
  elseif a:buffer =~# '^\d\+$'      " Str bufnr to bufnr
    return bufnr(str2nr(a:buffer))
  else                              " Bufname to bufnr
    return bufnr(a:buffer)
  endif
endfunction


function! s:new_tmp_buf(bang)
  execute 'enew' . a:bang
  setl noswapfile
  " If empty and out of sight, delete it right away
  setl bufhidden=wipe
  " Regular buftype warns people if they have unsaved text there
  setl buftype=
endfunction


function! s:del_buf(bufNr, bufDeleteCmd, bang)
  let curTabNr = tabpagenr()
  let command = a:bufDeleteCmd . a:bang . ' '

  " Store listed buffers count
  let bufCount = len(getbufinfo({'buflisted':1}))

  if bufCount ># 1
    " Prevent tabs and windows from closing if pointing to the same curBuf
    " by switching to next buffer before deleting curBuf
    call s:shift_win_buf_pointing_to_cur_buf(a:bufNr)

    " Close buffer and restore active tab
    execute command . a:bufNr
    silent execute 'tabn ' . curTabNr
    " Create blank buffer if ended up with unmodifiable buffer
    if !&modifiable
      call s:new_tmp_buf('!')
    endif
  else
    execute command . a:bufNr
  endif
endfunction


" Quit all diff buffers
function! s:close_diff_bufs(bang)
  for bufNr in range(1, bufnr('$'))
    if getwinvar(bufwinnr(bufNr), '&diff') == 1
      " Go to the diff buffer window and quit
      execute bufwinnr(bufNr) . 'wincmd w | ' . 'bd' . a:bang
    endif
  endfor
endfunction


" Hacky workaround to delete buffer while in Goyo mode without exiting or
" to turn off Goyo mode when only one buffer exists
function! s:del_goyo_buf(bang) abort
  let bufCount = len(getbufinfo({'buflisted':1}))
  if bufCount ># 1
    execute 'bn | ' . 'bd' . a:bang . '#'
  else
    execute 'q' . a:bang . ' | bn'
    call smartq#wipe_empty_bufs('!')
  endif
endfunction


" Count all modifiable splits excluding given filetype and buftype list
function! s:count_mod_splits()
  let splitsCount = 0
  if winnr('$') ># 1
    for _ in range(1, winnr('$'))
      if &modifiable
            \ && index(g:smartq_exclude_filetypes, &filetype) < 0
            \ && index(g:smartq_exclude_buftypes, &buftype) < 0
        let splitsCount += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsCount
  endif

  return 1
endfunction


function! s:is_buf_excl()
  let filetype = &filetype
  let buftype = &buftype
  if (filetype !=# '' && index(g:smartq_exclude_filetypes, filetype) >=# 0)
        \ || (buftype !=# '' && index(g:smartq_exclude_buftypes, buftype) >=# 0)
    return 1
  else
    return 0
  endif
endfunction


function! s:is_buf_q()
  let filetype = &filetype
  let buftype = &buftype
  if (filetype !=# '' && index(g:smartq_q_filetypes, filetype) >=# 0)
        \ || (buftype !=# '' && index(g:smartq_q_buftypes, buftype) >=# 0)
        \ || !&modifiable || &readonly
    return 1
  else
    return 0
  endif
endfunction


function! s:is_buf_bw()
  let filetype = &filetype
  let buftype = &buftype
  if (filetype !=# '' && index(g:smartq_bw_filetypes, filetype) >=# 0)
        \ || (buftype !=# '' && index(g:smartq_bw_buftypes, buftype) >=# 0)
    return 1
  else
    return 0
  endif
endfunction


" Close all modifiable splits excluding given filetype and buftype list
function! smartq#close_mod_splits()
  let splitsClosed = 0
  if s:count_mod_splits() ># 1
    for _ in range(1, winnr('$') - 1)
      if &modifiable
            \ && index(g:smartq_exclude_filetypes, &filetype) < 0
            \ && index(g:smartq_exclude_buftypes, &buftype) < 0
        silent execute "close!"
        let splitsClosed += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsClosed
  endif
endfunction


function! smartq#wipe_empty_bufs(bang)
  let emtpyBufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) > 0')
  if !empty(emtpyBufs)
    execute 'bw' . a:bang . ' ' . join(emtpyBufs, ' ')
  endif
endfunction


function! smartq#smartq(bang, buffer) abort
  " Exit if filetype excluded
  if s:is_buf_excl()
    return
  endif

  let bufNr = s:str_to_bufnr(a:buffer)
  let bufName = bufname(bufNr)
  let curTabNr = tabpagenr()

  if getbufvar(bufNr, '&modified') == 1 && &confirm ==# 0 && empty(a:bang)
    echohl WarningMsg | echo "Changes detected. Please save your file(s) (add ! to override)" | echohl None
    return
  endif

  let splitCount = s:count_mod_splits()
  let bang = &buftype ==# 'terminal' ? '!' : a:bang

  " Listed buffers
  let bufCount = len(getbufinfo({'buflisted':1}))

  if &diff                                        " Diff
    call s:close_diff_bufs(bang)
  elseif exists("#goyo")                          " Goyo
    call s:del_goyo_buf(bang)
  elseif splitCount ># 1                          " Split > 1
        \ && bufCount ==# 1 && bufName ==# ''
    call smartq#close_mod_splits()
  elseif splitCount ==# 1                         " Split = 1
        \ && bufCount ==# 1 && bufName ==# ''
    execute 'q' . bang
  elseif s:is_buf_q()                             " q
    execute 'q' . bang
  elseif splitCount ==# 1 && tabpagenr('$') > 1   " Split = 1, Tab > 1
    if s:is_buf_bw()
      execute 'bw' . bang . bufNr
    else
      execute 'bd' . bang . bufNr
    endif
  elseif s:is_buf_bw()                            " bw
    call s:del_buf(bufNr, 'bw', bang)
  else
    call s:del_buf(bufNr, 'bd', bang)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

