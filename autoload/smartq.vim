" File: smartq.vim
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
"   GPL3
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


function! s:shift_all_win_buf_pointing_to_cur_buf(buffer)
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
  silent execute 'enew' . a:bang
  setl noswapfile
  " If empty and out of sight, delete it right away
  setl bufhidden=wipe
  " Regular buftype warns people if they have unsaved text there
  setl buftype=
  " Hide the buffer from buffer explorers and tabbars
  setl nobuflisted
endfunction


function! s:delete_buf_preserve_split(bufNr, bufDeleteCmd, bang)
  let curTabNr = tabpagenr()
  let command = a:bufDeleteCmd . a:bang

  " Store listed buffers count
  let bufCount = len(getbufinfo({'buflisted':1}))

  if bufCount ># 1
    " Prevent tabs and windows from closing if pointing to the same curBuf
    " by switching to next buffer before deleting curBuf
    call s:shift_all_win_buf_pointing_to_cur_buf(a:bufNr)

    " Close buffer and restore active tab
    execute command . a:bufNr
    silent execute 'tabn ' . curTabNr
    " Create blank buffer if ended up with unmodifiable buffer
    if !&modifiable
      silent execute 'enew' . a:bang
    endif
  else
    " Create new buffer empty if no splits and delete curBuf
    silent execute 'enew' . a:bang
    call s:shift_all_win_buf_pointing_to_cur_buf(a:bufNr)
    execute a:bufNr . command
  endif
endfunction


" Quit all diff buffers
function! s:close_diff_bufs(bang)
  for bufNr in range(1, bufnr('$'))
    if getwinvar(bufwinnr(bufNr), '&diff') == 1
      " Go to the diff buffer window and quit
      silent execute bufwinnr(bufNr) . 'wincmd w | ' . 'bd' . a:bang
    endif
  endfor
endfunction


" Hacky workaround to delete buffer while in Goyo mode without exiting or
" to turn off Goyo mode when only one buffer exists
function! s:delete_goyo_buf(bang)
  let bufCount = len(getbufinfo({'buflisted':1}))
  if bufCount ># 1
    silent execute 'bn | ' . 'bd' . a:bang . '#'
  else
    silent execute 'q' . a:bang . ' | bn'
    call smartq#wipe_empty_buffers('!')
  endif
endfunction


function! s:count_all_modifiable_splits_with_exclusion()
  let splitsCount = 0
  if winnr('$') ># 1
    for _ in range(1, winnr('$'))
      if index(g:smartq_exclude_filetypes, &filetype) < 0 && &modifiable
        let splitsCount += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsCount
  endif

  return 1
endfunction


function! smartq#wipe_empty_buffers(bang) abort
  let emtpyBufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val)<0 && !getbufvar(v:val, "&mod")')
  if !empty(emtpyBufs)
    silent execute 'bw' . a:bang . ' ' . join(emtpyBufs, ' ')
  endif
endfunction


" Close all modifiable splits excluding given filetype list
function! smartq#close_all_modifiable_splits() abort
  let splitsClosed = 0
  if s:count_all_modifiable_splits_with_exclusion() ># 1
    for _ in range(1, winnr('$') - 1)
      if index(g:smartq_exclude_filetypes, &filetype) < 0 && &modifiable
        silent execute "close!"
        let splitsClosed += 1
      endif
      silent execute "wincmd w"
    endfor
    return splitsClosed
  endif
endfunction


function! smartq#smartq(bang, buffer) abort
  " Exit if filetype excluded
  if index(g:smartq_exclude_filetypes, &filetype) >= 0
    return
  endif

  let bufNr = s:str_to_bufnr(a:buffer)
  let bufName = bufname(bufNr)
  let curTabNr = tabpagenr()

  if getbufvar(bufNr, '&modified') == 1 && empty(a:bang)
    echohl WarningMsg | echo "Changes detected. Please save your file(s) (add ! to override)" | echohl None
    return
  endif

  let bdFiletypes = join(g:smartq_bd_filetypes, '\|')
  let bwFiletypes = join(g:smartq_bw_filetypes, '\|')
  let qFiletypes = join(g:smartq_q_filetypes, '\|')

  let splitCount = s:count_all_modifiable_splits_with_exclusion()

  " Store listed buffers count
  let bufCount = len(getbufinfo({'buflisted':1}))

  if &buftype ==# 'terminal'
    silent execute 'bw!'

  elseif &diff
    call s:close_diff_bufs(a:bang)

  elseif exists("#goyo")
    call s:delete_goyo_buf(a:bang)

  elseif splitCount ># 1 && bufCount ==# 1 && bufName ==# ''
    call smartq#close_all_modifiable_splits()

  elseif splitCount ==# 1 && bufCount ==# 1 && bufName ==# ''
    silent execute 'q' . a:bang

  elseif splitCount ==# 1 && tabpagenr('$') > 1
    if bwFiletypes =~ &filetype
      execute 'bw' . a:bang . bufNr
    else
      execute 'bd' . a:bang . bufNr
    endif

  elseif bdFiletypes =~ &filetype
    call s:delete_buf_preserve_split(bufNr, 'bd', a:bang)

  elseif bwFiletypes =~ &filetype
    call s:delete_buf_preserve_split(bufNr, 'bw', a:bang)

  elseif qFiletypes =~ &filetype || ((!&modifiable || &readonly) && bufName ==# '')
    silent execute 'q' . a:bang

  else
    call s:delete_buf_preserve_split(bufNr, 'bd', a:bang)

  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

