# vim-smartq

Master key for quitting vim buffers.

Exit/Delete buffer with respect to window splits and tabs, and other types of
buffer.

## Features

Preserve splits across tabs

![Preserve Splits](https://i.imgur.com/uKRWrjS.gif)

[Goyo](https://github.com/junegunn/goyo.vim) Integration

![Goyo Integration](https://i.imgur.com/sB70XEK.gif)

Close all diff buffers

![Diff](https://i.imgur.com/qSTQfGl.gif)

Additional features

- Close all splits in current tab when one empty modifiable buffer remaining
  with multiple splits.
- Auto wipe empty buffers when deleting/wiping a buffer

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

Plug and play. Automatically remap macro record `q` to `Q`, then map `q` to
`<Plug>(smartq_this)` and `<C-q>` to `<Plug>(smartq_this_force)`

```vim
:SmartQ {buffer}      " Smart quit (buffer name/number, optional)
:SmartQ! {buffer}     " Same as above but forced
:SmartQSave {buffer}  " Smart save before quit (buffer name/number, optional)
:SmartQWipeEmpty      " Wipe all empty (untitled) buffers
:SmartQWipeEmpty!     " Same as above but forced
:SmartQCloseSplits    " Close all splits excluding non-modifiable buffers
```

> Tip: SmartQ(!) accepts both buffer name and buffer number (see :buffers). Also
> supports tab completion.

## Mappings

```vim
nmap <Plug>(smartq_this)              " :SmartQ
nmap <Plug>(smartq_this_save)         " :SmartQSave
nmap <Plug>(smartq_this_force)        " :SmartQ!
nmap <Plug>(smartq_wipe_empty)        " :SmartQWipeEmpty
nmap <Plug>(smartq_wipe_empty_force)  " :SmartQWipeEmpty!
nmap <Plug>(smartq_close_splits)      " :SmartQCloseSplits
```

## Customization

```vim
" Default Settings
" -----

" Default mappings:
" Remaps normal mode macro record q to Q
" nnoremap Q q
" nmap q        <Plug>(smartq_this)
" nmap <C-q>    <Plug>(smartq_this_force)
let g:smartq_default_mappings = 1

" Excluded buffers to disable SmartQ and to preserve windows when closing splits
" on excluded buffers. Non-modifiable buffers are preserved by default.
let g:smartq_exclude_filetypes = [
      \ 'fugitive'
      \ ]
let g:smartq_exclude_buftypes= [
      \ ''
      \ ]

" Quit buffers using :q command. Non-modifiable and readonly file uses :q
let g:smartq_q_filetypes = [
      \ 'diff', 'git', 'gina-status', 'gina-commit', 'snippets',
      \ 'floaterm'
      \ ]
let g:smartq_q_buftypes = [
      \ 'quickfix', 'nofile'
      \ ]

" Wipe buffers using :bw command. Wiped buffers are removed from jumplist
" Default :bd
let g:smartq_bw_filetypes = [
      \ ''
      \ ]
let g:smartq_bw_buftypes = [
      \ ''
      \ ]

" Automatically wipe empty (with no changes) buffer(s)
let g:smartq_auto_wipe_emtpy = 1
" Automatically close splits when left with an empty modifiable buffer
let g:smartq_auto_close_splits = 1
" Best attemp to prevent exiting editor when left with an empty modifiable buffer
let g:smartq_no_exit = 0
```

## SmartQ Quit Prioritization

Ordered list of SmartQ quit conditions. Once `SmartQ` command is executed, it
will find and **ONLY EXECUTE ONE** condition from the list below.

1. **Delete** (`bd`) all `diff` buffers. Check: `:set diff?`
2. **Delete** (`bd`) [Goyo](https://github.com/junegunn/goyo.vim) buffer
3. On final buffer
  i. **Close** (`close!`) all `modifiable` windows OR **Quit all** (`qa`) if empty buffer
4. On final buffer with `nomodifiable` window(s)
  i. **Quit all** (`qa`) if empty buffer
5. **Quit** (`q`)
  - `smartq_q_filetypes` or `smartq_q_buftypes`
  - `terminal` buffer
  - `nomodifiable` or `readonly` window
  - Exceptions: `smartq_exclude_filetypes`, `smartq_exclude_buftypes`, empty `filetype` and `buftype`
5. **Wipe** (`bw`)
  - `smartq_bw_filetypes` or `smartq_bw_buftypes`
  - Exceptions: `smartq_exclude_filetypes`, `smartq_exclude_buftypes`, empty `filetype` and `buftype`
6. Catch all: **Delete** (`bd`) buffer. Check: `:buffers`

See `diff`, `modifiable`, `filetype`, `buftype`, `buffers`


## Credits

- [cespare/vim-sbd](https://github.com/cespare/vim-sbd)
- [moll/vim-bbye](https://github.com/moll/vim-bbye)
- [Asheq/close-buffers.vim](https://github.com/Asheq/close-buffers.vim)

