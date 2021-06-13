# vim-smartq

Master key for quitting vim buffers.

Sensibly close buffers with respect to alternate tabs and window splits, and
other types of buffer.

## Features

Preserve splits across tabs

![Preserve Splits](https://i.imgur.com/uKRWrjS.gif)

[Goyo](https://github.com/junegunn/goyo.vim) Integration

![Goyo Integration](https://i.imgur.com/sB70XEK.gif)

Close all diff buffers

![Diff](https://i.imgur.com/qSTQfGl.gif)

Additional features

- Close all splits in current tab when one empty buffer remaining with multiple
  splits.
- Close terminal.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'marklcrns/vim-smartq'
```

Using [dein](https://github.com/Shougo/dein.vim)

```vim
call dein#add('marklcrns/vim-smartq')
```

## Usage

```vim
:SmartQ               " Smart quit
:SmartQCloseSplits    " Wipe all empty buffers
:SmartQWipeEmpty      " Close all splits excluding non-modifiable
                      " buffers and g:smartq_exclude_filetypes
```

## Mappings

```vim
nmap <Plug>(smartq_smartq)         " :SmartQ
nmap <Plug>(smartq_wipe_empty)     " :SmartQWipeEmpty
nmap <Plug>(smartq_close_splits)   " :SmartQCloseSplits
```

## Customization

```vim
" Default Settings
" -----

" Remaps normal mode macro record q to Q, then assign q <Plug>(smartq_smartq)
let g:smartq_default_mappings = 1

" Excluded filetypes to disable SmartQ and to preserve windows when closing
" splits on excluded buffers. Non-modifiable are preserved by default.
let g:smartq_exclude_filetypes = [
      \ 'fugitive'
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
```

