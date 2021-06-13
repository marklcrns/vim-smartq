" File: smartq.vim
"
" Description:
"   Sensibly close buffers with respect to alternate tabs and window splits,
"   and other types of buffer.
"
" Features:
"   - Delete buffers with preserving tabs and window splits displaying the same
"     buffer to be deleted.
"   - Keep tabs and window splits open with an empty buffer if pointing to
"     same buffer to be deleted.
"   - Prevents from deleting buffer if modified or in g:smartq_exclude_filetypes
"   - Handles diff splits, closing all diff buffer windows automatically.
"   - Goyo integration. Remain in Goyo tab when deleting buffers. Exists if only
"     one buffer remains.
"
" Author:
"   Mark Lucernas
"   https://github.com/marklcrns
"   2021-06-12
"
" Commands:
"   :SmartQ
"   :SmartQCloseSplits
"   :SmartQWipeEmpty
"
" Credits:
"   smartq#wipe_empty_buffers()
"     - https://stackoverflow.com/a/10102604
"   smartq#smartq()
"     - https://github.com/cespare/vim-sbd
"     - https://stackoverflow.com/a/29236158
"     - https://superuser.com/questions/345520/vim-number-of-total-buffers
"

if exists('g:smartq_loaded')
  finish
endif
let g:smartq_loaded = 1


let s:save_cpo = &cpo
set cpo&vim


function! s:ShiftAllWindowsBufferPointingToBuffer(buffer)
  " Loop through tabs
  for i in range(1, tabpagenr('$'))
    execute 'tabnext ' . i
    if winnr('$') ># 1
      " Store active window nr to restore later
      let s:curWin = winnr()

      " Loop over windows pointing to curBuf
      let s:winnr = bufwinnr(a:buffer)
      while (s:winnr >= 0)
        " Go to window and switch to next buffer
        execute s:winnr . 'wincmd w | bnext'
        " Restore active window
        execute s:curWin . 'wincmd w'
        let s:winnr = bufwinnr(a:buffer)
      endwhile
    endif
  endfor
endfunction


function! s:DeleteBufPreservingSplit(bufNr, bufDeleteCmd)
  let s:curTabNr = tabpagenr()

  " Store listed buffers count
  let s:curBufCount = len(getbufinfo({'buflisted':1}))

  if s:curBufCount ># 1
    " Prevent tabs and windows from closing if pointing to the same curBuf
    " by switching to next buffer before deleting curBuf
    call s:ShiftAllWindowsBufferPointingToBuffer(a:bufNr)

    " Close buffer and restore active tab
    silent execute a:bufDeleteCmd . a:bufNr
    silent execute 'tabn ' . s:curTabNr
    " Create blank buffer if ended up with unmodifiable buffer
    if !&modifiable
      silent execute 'enew'
    endif
  else
    " Create new buffer empty if no splits and delete curBuf
    silent execute 'enew'
    call s:ShiftAllWindowsBufferPointingToBuffer(a:bufNr)
    silent execute a:bufNr . a:bufDeleteCmd
  endif
endfunction


" Quit all diff buffers
function! s:CloseDiffBuffers()
  for bufNr in range(1, bufnr('$'))
    if getwinvar(bufwinnr(bufNr), '&diff') == 1
      " Go to the diff buffer window and quit
      execute bufwinnr(bufNr) . 'wincmd w | bd'
    endif
  endfor
endfunction


" Hacky workaround to delete buffer while in Goyo mode without exiting or
" to turn off Goyo mode when only one buffer exists
function! s:CloseGoyoBuffer()
  if s:curBufCount ># 1
    silent execute 'bn | bd#'
  else
    silent execute 'q | bn'
    call smartq#wipe_empty_buffers()
  endif
endfunction


function! s:CountAllModifiableSplitsWithExclusion()
  let s:splits = 0
  if winnr('$') ># 1
    for _ in range(1, winnr('$'))
      if index(g:smartq_exclude_filetypes, &filetype) < 0 && &modifiable
        let s:splits += 1
      endif
      silent execute "wincmd w"
    endfor
    return s:splits
  endif

  return 1
endfunction


function! smartq#wipe_empty_buffers() abort
  let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val)<0 && !getbufvar(v:val, "&mod")')
  if !empty(buffers)
    " Wipe all empty buffers
    execute 'bw! ' . join(buffers, ' ')
  endif
endfunction


" Close all modifiable splits excluding given filetype list
function! smartq#close_all_modifiable_splits() abort
  let s:splitsClosed = 0
  if s:CountAllModifiableSplitsWithExclusion() ># 1
    for _ in range(1, winnr('$') - 1)
      if index(g:smartq_exclude_filetypes, &filetype) < 0 && &modifiable
        silent execute "close!"
        let s:splitsClosed += 1
      endif
      silent execute "wincmd w"
    endfor
    echo "splits closed " . s:splitsClosed
    return s:splitsClosed
  endif
endfunction


function! smartq#smartq() abort
  if index(g:smartq_exclude_filetypes, &filetype) >= 0
    return
  endif

  let s:curBufNr = bufnr('%')
  let s:curBufName = bufname('%')
  let s:curTabNr = tabpagenr()

  if getbufvar(s:curBufNr, '&modified') == 1
    echohl WarningMsg | echo "Changes detected. Please save your file(s)" | echohl None
    return
  endif

  let s:bdFiletypes = join(g:smartq_bd_filetypes, '\|')
  let s:bwFiletypes = join(g:smartq_bw_filetypes, '\|')
  let s:qFiletypes = join(g:smartq_q_filetypes, '\|')

  " Store listed buffers count
  let s:curBufCount = len(getbufinfo({'buflisted':1}))

  if &buftype ==# 'terminal'
    silent execute 'bw!'
  elseif &diff
    call s:CloseDiffBuffers()
  elseif exists("#goyo")
    call s:CloseGoyoBuffer()
  elseif s:curBufCount ==# 1 && s:CountAllModifiableSplitsWithExclusion() > 1
    echomsg "Closing all splits"
    " Close all splits if exists, else quit vim
    call smartq#close_all_modifiable_splits()
  elseif s:curBufCount ==# 1 && s:CountAllModifiableSplitsWithExclusion() ==# 1 && s:curBufName ==# ''
    echomsg "Quitting"
    silent execute 'qa!'
  elseif s:bdFiletypes =~ &filetype
    echomsg "deleting with bd"
    call s:DeleteBufPreservingSplit(s:curBufNr, 'bd')
  elseif s:bwFiletypes =~ &filetype
    echomsg "deleting with bw"
    call s:DeleteBufPreservingSplit(s:curBufNr, 'bw')
  elseif s:qFiletypes =~ &filetype || (!&modifiable || &readonly)
    silent execute 'q'
  else
    echomsg "else, deleting with bd"
    call s:DeleteBufPreservingSplit(s:curBufNr, 'bd')
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

