# vim-smartq

Master key for quitting vim buffers.

Sensibly close buffers with respect to alternate tabs and window splits, and
other types of buffer.

## Features

Preserve splits across tabs

![Preserve Splits](https://i.imgur.com/uKRWrjS.gif)

Goyo Integration

![Goyo Integration](https://i.imgur.com/sB70XEK.gif)

Close all diff buffers

![Diff](https://i.imgur.com/qSTQfGl.gif)

Additional features

- Auto delete empty buffers.
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
" Remap macro key to Q
nnoremap Q q
" Map SmartQ to q
nnoremap q :SmartQ<cr>
```

## Customization

```vim
" Default Settings

" Prevent SmartQ from quitting some filetypes
let g:smartq_exclude_filetypes = [
     \ 'vista', 'fern', 'NvimTree', 'Mundo', 'MundoDiff', 'minimap',
     \ 'fugitive', 'gitcommit'
     \ ]
" Quit filetypes using :bd command
let g:smartq_bd_filetypes = [
    \ 'git', 'gina-', 'qf'
    \ ]
" Quit filetypes using :q command
let g:smartq_q_filetypes = [
    \ 'gitcommit', 'diff'
    \ ]
```
