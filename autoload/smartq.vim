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
          silent execute 'bnext'
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
    return bufnr('%')
  elseif a:buffer =~# '^\d\+$'      " Str bufnr to bufnr
    return bufnr(str2nr(a:buffer))
  else                              " Bufname to bufnr
    return bufnr(a:buffer)
  endif
endfunction


function! s:new_tmp_buf(bang)
  silent execute 'enew' . a:bang
  setl noswapfile
  setl bufhidden=wipe
  setl buftype=
endfunction


function! s:del_buf(bufNr, bufDeleteCmd, bang)
  let command = a:bufDeleteCmd . a:bang . ' '

  " Store listed buffers count
  let bufCount = len(getbufinfo({'buflisted':1}))

  " Prevent tabs and windows from closing if pointing to the same curBuf
  if getbufvar(a:bufNr, '&modifiable')
    call s:shift_win_buf_pointing_to_cur_buf(a:bufNr)
  endif

  silent execute command . a:bufNr

  if bufCount ># 1 || g:smartq_auto_close_splits ==# 1
    call smartq#wipe_empty_bufs(a:bang)
  endif
  " POSSIBLY UNREACHABLE: If left with non-modifiable buffer, create blank
  if !&modifiable
    call s:new_tmp_buf('!')
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


" Hacky workaround to delete buffer while in Goyo mode without exiting and
" to turn off Goyo mode when only one buffer exists
function! s:del_goyo_buf(bang) abort
  let bufCount = len(getbufinfo({'buflisted':1}))
  if bufCount ># 1
    silent execute 'bn | ' . 'bd' . a:bang . '#'
  else
    silent execute 'q' . a:bang . ' | bn'
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
      silent execute 'wincmd w'
    endfor
    return splitsCount
  endif

  return 1
endfunction


" Close all modifiable splits
function! smartq#close_mod_splits(bang)
  if g:smartq_auto_close_splits ==# 0 && a:bang ==# ''
    return
  endif

  if s:count_mod_splits() ># 1
    for _ in range(1, winnr('$') - 1)
      if &modifiable
        silent execute 'close!'
      endif
      silent execute 'wincmd w'
    endfor
    return 1
  endif
  return 0
endfunction


function! s:is_buf_excl()
  let filetype = &filetype
  let buftype = &buftype
  if (filetype !=# '' && index(g:smartq_exclude_filetypes, filetype) >=# 0)
        \ || (buftype !=# '' && index(g:smartq_exclude_buftypes, buftype) >=# 0)
    return 1
  endif
  return 0
endfunction


function! s:is_buf_q()
  let filetype = &filetype
  let buftype = &buftype
  if buftype ==# 'terminal'
    return 0
  elseif (filetype !=# '' && index(g:smartq_q_filetypes, filetype) >=# 0)
        \ || (buftype !=# '' && index(g:smartq_q_buftypes, buftype) >=# 0)
        \ || !&modifiable || &readonly
    return 1
  endif
  return 0
endfunction


function! s:is_buf_bw()
  let filetype = &filetype
  let buftype = &buftype
  if (filetype !=# '' && index(g:smartq_bw_filetypes, filetype) >=# 0)
        \ || buftype ==# 'terminal'
        \ || (buftype !=# '' && index(g:smartq_bw_buftypes, buftype) >=# 0)
    return 1
  endif
  return 0
endfunction

function! s:is_floating(id) abort
  if has('nvim')
    let l:cfg = nvim_win_get_config(a:id)
    return !empty(l:cfg.relative) || l:cfg.external
  endif
  return 0
endfunction

function! s:echo_error(msg, newline)
  let message = '[vim-smartq] ERROR: ' . a:msg

  if a:newline ==# 1
    message = '\n' . message
  endif

  echohl WarningMsg | echom message | echohl None
endfunction

function! s:echo_info(msg, newline)
  let message = '[vim-smartq] INFO: ' . a:msg

  if a:newline ==# 1
    message = '\n' . message
  endif

  echom message
endfunction

function! s:echo_msg(msg, newline)
  let message = '[vim-smartq]: ' . a:msg

  if a:newline ==# 1
    message = '\n' . message
  endif

  echo message
endfunction

function! s:confirm_prompt(msg)
  call s:echo_msg(a:msg . ' [y/n] ', 0)
  let answer = nr2char(getchar())

  if answer ==? 'y'
    return 1
  elseif answer ==? 'n'
    return 0
  elseif answer ==# ''
    call s:echo_error('Aborted!', 0)
    return 0
  else
    echo 'Please enter "y" or "n"'
    return s:confirm_prompt(a:msg)
  endif
endfunction

function! s:save_buf(bang, bufName)
  try
    exec 'w' . a:bang . ' ' . a:bufName
  " No file name
  catch E32
    let root = getcwd() . '/'
    let newfile = input('New filename: ' . root, '', 'file')

    if empty(newfile)
      call s:echo_error("Saving buffer '" . a:bufName . "' aborted!", 1)
      return 1
    elseif isdirectory(newfile)
      call s:echo_error(newfile . ' is a directory!', 1)
      return 2
    endif
    let dir=fnamemodify(newfile, ':h')
    if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif
    exec 'w' . a:bang . ' ' . newfile
    return 0
  endtry

  call s:echo_error('Error writting to buffer ' . a:bufName . ' aborted!', 1)
  return 1
endfunction


function! smartq#wipe_empty_bufs(bang)
  if g:smartq_auto_wipe_emtpy ==# 0 && a:bang ==# ''
    return 0
  endif

  let emtpyBufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) > 0')
  if !empty(emtpyBufs)
    silent execute 'bw' . a:bang . ' ' . join(emtpyBufs, ' ')
    return 1
  endif

  return 0
endfunction


function! smartq#smartq(bang, buffer, save) abort
  " Exit if filetype excluded
  if s:is_buf_excl()
    return
  elseif s:is_floating(0) " Neovim only
    silent execute 'q'
    return
  endif

  let bufNr = s:str_to_bufnr(a:buffer)
  let bufName = bufname(bufNr)
  let curTabNr = tabpagenr()

  let modSplitsCount = s:count_mod_splits()
  let bang = &buftype ==# 'terminal' ? '!' : a:bang

  " Save before quit
  if &modifiable && getbufvar(bufNr, '&modified') == 1
    if a:save ==# v:true
      let save = s:save_buf(a:bang, bufName)
      if save ==# 1
        return
      elseif save ==# 2
        if s:confirm_prompt('Buffer could not be saved, proceed quit?')
          let bang = '!'
        else
          return
        endif
      endif
    elseif &confirm ==# 0 && empty(a:bang)
      call s:echo_error('Changes detected. Please save your file(s) (add ! to override)', 0)
      return
    endif
  endif

  " Listed buffers
  let bufCount = len(getbufinfo({'buflisted':1}))

  if &diff                                        " Diff
    call s:close_diff_bufs(bang)
  elseif exists('#goyo')                          " Goyo
    call s:del_goyo_buf(bang)
  elseif modSplitsCount ># 1 && bufCount ==# 1 && bufName ==# ''
    " If close splits not successful, quit all
    if !smartq#close_mod_splits(bang)
      if g:smartq_no_exit ==# 0
        silent execute 'qa' . bang
      else
        call s:echo_msg('Exit prevented. Only one buffer left.', 0)
      endif
    endif
  elseif modSplitsCount ==# 1 && bufCount ==# 1 && bufName ==# ''
    if g:smartq_no_exit ==# 0 || bang ==# '!'
      silent execute 'qa' . bang
    else
      call s:echo_msg('Exit prevented. Only one buffer left.', 0)
    endif
  elseif s:is_buf_q()                             " q
    silent execute 'q' . bang
  elseif s:is_buf_bw()                            " bw
    call s:del_buf(bufNr, 'bw', bang)
  else
    call s:del_buf(bufNr, 'bd', bang)
  endif

  return
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

