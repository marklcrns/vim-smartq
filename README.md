# vim-smartq

Master key for quitting vim buffers.

Sensibly close buffers with respect to alternate tabs and window splits, and
other types of buffer.

## Usage

```vim
" Remap macro key to Q
nnoremap Q q
" Map SmartQ to q
nnoremap q :SmartQ<cr>
```

## Default Settings

```vim
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
