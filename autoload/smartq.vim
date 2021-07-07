" smartq.vim
" Version: 1.2
"
" Description:
"   Sensibly close buffers with respect to alternate tabs and window splits,
"   and other types of buffer.
" Features:
"   - Delete buffers with preserving tabs and window splits displaying the same
"     buffer to be deleted. Auto wipe empty buffer when deleting/wiping buffers.
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
" Refs:
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


function! s:shift_win_buf_pointing_to_cur_buf(bufNr)
  let bufCount = len(getbufinfo({'buflisted':1}))
  let curTabNr = tabpagenr()

  if bufCount ==# 1 && bufname(a:bufNr) ==# ''
    return
  endif

  for i in range(1, tabpagenr('$'))
    silent execute 'tabnext ' . i
    if winnr('$') ># 1
      " Store active window nr to restore later
      let curWin = winnr()
      " Loop over windows pointing to curBuf
      let winnr = bufwinnr(a:bufNr)
      while (winnr >= 0)
        " Go to window and switch to next buffer
        silent execute winnr . 'wincmd w'
        if len(getbufinfo({'buflisted':1})) ==# 1
          call s:new_tmp_buf('!')
        else
          execute 'bnext'
        endif
        " Restore active window
        silent execute curWin . 'wincmd w'
        let winnr = bufwinnr(a:bufNr)
      endwhile
    endif
  endfor

  " Restore active tab
  silent execute 'tabn ' . curTabNr
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
  setl bufhidden=wipe
  setl buftype=
endfunction


function! s:del_buf(bufNr, bufDeleteCmd, bang)
  let command = a:bufDeleteCmd . a:bang . ' '

  " Store listed buffers count
  let bufCount = len(getbufinfo({'buflisted':1}))

  " Prevent tabs and windows from closing if pointing to the same curBuf
  call smartq#wipe_empty_bufs(a:bang)
  call s:shift_win_buf_pointing_to_cur_buf(a:bufNr)
  execute command . a:bufNr

  if !&modifiable
    call s:new_tmp_buf('!')
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


" Hacky workaround to delete buffer while in Goyo mode without exiting and
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


" Count all modifiable splits
function! s:count_mod_splits()
  let splitsCount = 0
  if winnr('$') ># 1
    for _ in range(1, winnr('$'))
      if &modifiable
        let splitsCount += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsCount
  endif

  return 1
endfunction


" Close all modifiable splits
function! smartq#close_mod_splits()
  let splitsClosed = 0
  if s:count_mod_splits() ># 1
    for _ in range(1, winnr('$') - 1)
      if &modifiable
        silent execute "close!"
        let splitsClosed += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsClosed
  endif
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

  let modSplitsCount = s:count_mod_splits()
  let bang = &buftype ==# 'terminal' ? '!' : a:bang

  " Listed buffers
  let bufCount = len(getbufinfo({'buflisted':1}))

  if &diff                                        " Diff
    call s:close_diff_bufs(bang)
  elseif exists("#goyo")                          " Goyo
    call s:del_goyo_buf(bang)
  elseif modSplitsCount ># 1 && bufCount ==# 1 && bufName ==# ''
    call smartq#close_mod_splits()
  elseif modSplitsCount ==# 1 && bufCount ==# 1 && bufName ==# ''
    execute 'qa' . bang
  elseif s:is_buf_q()                             " q
    execute 'q' . bang
  elseif s:is_buf_bw()                            " bw
    call s:del_buf(bufNr, 'bw', bang)
  else
    call s:del_buf(bufNr, 'bd', bang)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

