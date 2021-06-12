" File: smartq.vim
"
" Author:
"   Mark Lucernas
"   https://github.com/marklcrns
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
"   - Auto delete empty buffers (will close tabs and window splits).
"   - Prevents from deleting buffer if modified.
"   - Handles diff splits, closing all diff buffer windows automatically.
"
" Commands:
"   :SmartQ
"
" Mappings:
"   noremap q :SmartQ<CR>
"
" Credits:
"   - CleanEmptyBuffers()
"     https://stackoverflow.com/a/10102604
"   - SmartQ()
"     https://github.com/cespare/vim-sbd
"     https://stackoverflow.com/a/29236158
"     https://superuser.com/questions/345520/vim-number-of-total-buffers
"

if get(g:, 'smartq_loaded', 0) !=# 0
  finish
endif
let g:smartq_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

" List of excluded filetypes to preserve windows when clearing splits
" see CloseAllModifiableWin()
let g:smartq_exclude_filetypes = [
     \ 'vista', 'fern', 'NvimTree', 'Mundo', 'MundoDiff', 'minimap',
     \ 'fugitive', 'gitcommit'
     \ ]

let g:smartq_bd_filetypes = [
    \ 'git', 'gina-', 'qf'
    \ ]

let g:smartq_q_filetypes = [
    \ 'gitcommit', 'diff'
    \ ]

function! s:CleanEmptyBuffers()
  let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val)<0 && !getbufvar(v:val, "&mod")')
  if !empty(buffers)
    " Wipe all empty buffers
    execute 'bw ' . join(buffers, ' ')
  endif
endfunction

function! s:ShiftAllWindowsBufferPointingToBuffer(buffer)
  " Loop through tabs
  for i in range(1, tabpagenr('$'))
    " Go to tab
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

" Close all splits excluding given filetype list
function! s:CloseAllModifiableWin()
  let s:splitsClosed = 0
  " Close window splits if > 1
  if winnr('$') ># 1
    " Loop over window splits
    for _ in range(1, winnr('$'))
      " Close window splits if not in filetype exclusions, is modifiable, or empty
      if (index(g:smartq_exclude_filetypes, &filetype) < 0 || &modifiable) && &ft ==# ''
        execute "silent! close"
        let s:splitsClosed += 1
      endif
      " Go to next window
      silent execute "wincmd w"
    endfor
    echo "splits closed " . s:splitsClosed
  endif

  " Return total window splits closed
  return s:splitsClosed
endfunction


function! s:DeleteBufPreservingSplit(bufNr)
  let s:curTabNr = tabpagenr()

  " Store listed buffers count
  let s:curBufCount = len(getbufinfo({'buflisted':1}))

  if s:curBufCount ># 1
    " Prevent tabs and windows from closing if pointing to the same curBuf
    " by switching to next buffer before deleting curBuf
    call s:ShiftAllWindowsBufferPointingToBuffer(a:bufNr)

    " Close buffer and restore active tab
    silent execute 'silent! bdelete' . a:bufNr
    silent execute 'silent! tabnext ' . s:curTabNr
    " Create blank buffer if ended up with unmodifiable buffer
    if !&modifiable
      execute 'enew'
    endif
  else
    " Create new buffer empty if no splits and delete curBuf
    execute 'enew'
    call s:ShiftAllWindowsBufferPointingToBuffer(a:bufNr)
    execute "silent! " . a:bufNr . "bdelete"
  endif
endfunction


" Exits diff mode no matter where you are
" Optional arg to close specific plugin blob buffer
function! s:CloseDiffBuffers()
  " Loop over buffers
  for bufNr in range(1, bufnr('$'))
    if getwinvar(bufwinnr(bufNr), '&diff') == 1
      " Go to the diff buffer window and quit
      execute bufwinnr(bufNr) . 'wincmd w | bd'
    endif
  endfor
endfunction


function! <SID>SmartQ()
  if index(g:smartq_exclude_filetypes, &filetype) >= 0
    return
  endif

  let s:curBufNr = bufnr('%')
  let s:curBufName = bufname('%')
  let s:curTabNr = tabpagenr()

  let s:bdFiletypes = join(g:smartq_bd_filetypes, '\|')
  let s:qFiletypes = join(g:smartq_q_filetypes, '\|')

  call s:CleanEmptyBuffers()
  " Store listed buffers count
  let s:curBufCount = len(getbufinfo({'buflisted':1}))

  " Immediately quit/wipe certain buffers or filetype
  if &buftype ==# 'terminal'
    silent execute 'bw!'
    return
  elseif &diff
    call s:CloseDiffBuffers()
    return
  elseif exists("#goyo")
    " Hacky workaround to delete buffer while in Goyo mode without exiting or
    " to turn off Goyo mode when only one buffer exists
    if s:curBufCount ># 1
      silent execute 'bn | bd#'
    else
      silent execute 'q | bn'
      call s:CleanEmptyBuffers()
    endif
    return
  elseif &filetype =~ s:bdFiletypes
    silent execute 'bd'
    return
  elseif &filetype =~ s:qFiletypes || (!&modifiable || &readonly)
    silent execute 'q'
    return
  elseif ((s:curBufCount ==# 1 && s:curBufName ==# '') || &buftype ==# 'nofile') " Quit when only buffer and empty
    " Close all splits if exists, else quit vim
    if s:CloseAllModifiableWin() ==# 0
      silent execute 'qa!'
      return
    endif
  endif

  " Create empty buffer if only buffer w/o window splits, else close split
  if getbufvar(s:curBufNr, '&modified') == 1
    echohl WarningMsg | echo "Changes detected. Please save your file!" | echohl None
  else
    call s:DeleteBufPreservingSplit(s:curBufNr)
  endif
endfunction

if !exists(":SmartQ")
  command! -nargs=0 SmartQ call <SID>SmartQ()
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" DEPRECATED: For code reference only
" -----
" " Return true if has fugitive buffer open
" function! s:HasFugitiveDiffBuf()
"   for bufferNum in range(1, bufnr('$'))
"     if bufname(bufferNum) =~ '^fugitive:'
"       return v:true
"     endif
"   endfor
"   return v:false
" endfunction
"
" " Return true if has plugin buffer open
" function! s:HasPluginDiffBuf(pluginName)
"   for bufferNum in range(1, bufnr('$'))
"     if bufname(bufferNum) =~ '^' . a:pluginName . ':'
"       return v:true
"     endif
"   endfor
"   return v:false
" endfunction
"
" " If in fugitive blob buffer, close fugitive blob buffer and everything
" " related to it, else just close all fugitive blob buffer
" function! s:HandleFugitiveDiffBuffers()
"   if bufname('%') =~ '^fugitive:'
"     let fugitiveBlobBufPath= expand('#' . bufnr('%') . ':p')
"     " Delete all buffer with similar path to fugitive blob buffer
"     for bufferNum in range(1, bufnr('$'))
"       if bufname(bufferNum) =~ fugitiveBlobBufPath || bufname(bufferNum) =~ '^fugitive:'
"         silent execute 'bd ' . bufferNum
"       endif
"     endfor
"     " Delete fugitive blob buffer
"     call s:DeleteBufPreservingSplit(bufnr('%'))
"   else
"     " Delete all fugitive blob buffers
"     for bufferNum in range(1, bufnr('$'))
"       if bufname(bufferNum) =~ '^fugitive:'
"         silent execute 'bd ' . bufferNum
"       endif
"     endfor
"   endif
" endfunction
