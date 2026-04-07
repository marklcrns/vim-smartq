# vim-smartq

A smarter quit command for Vim buffers.

`vim-smartq` closes, deletes, or wipes the current buffer while preserving window
splits, tabs, and special buffer behavior where possible.

## Features

Preserve splits across tabs

![Preserve Splits](https://i.imgur.com/uKRWrjS.gif)

[Zen-mode](https://github.com/folke/zen-mode.nvim) Integration

![Zen-mode Integration](https://i.imgur.com/XuZZjaG.gif)

[Goyo](https://github.com/junegunn/goyo.vim) Integration

![Goyo Integration](https://i.imgur.com/sB70XEK.gif)

Close all diff buffers

![Diff](https://i.imgur.com/qSTQfGl.gif)

Additional features:

- Close all splits in the current tab when only one empty modifiable buffer
  remains across multiple splits.
- Automatically wipe empty buffers after deleting or wiping a buffer.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'marklcrns/vim-smartq'
```

Using [dein](https://github.com/Shougo/dein.vim)

```vim
call dein#add('marklcrns/vim-smartq')
```

Other package managers may be used as well.

## Usage

By default, `vim-smartq` remaps Vim's macro recording key from `q` to `Q`, maps
`q` to `<Plug>(smartq_this)`, and maps `<C-q>` to
`<Plug>(smartq_this_force)`.

```vim
:SmartQ {buffer}      " Smart quit (buffer name/number, optional)
:SmartQ! {buffer}     " Same as above but forced
:SmartQSave {buffer}  " Smart save before quit (buffer name/number, optional)
:SmartQWipeEmpty      " Wipe all empty (untitled) buffers
:SmartQWipeEmpty!     " Same as above but forced
:SmartQCloseSplits    " Close all splits excluding non-modifiable buffers
```

> Tip: `SmartQ` and `SmartQ!` accept a buffer name or buffer number
> (see `:buffers`) and support tab completion.

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

" Quit buffers using :q command. Non-modifiable and readonly buffers use :q
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

" Automatically wipe empty unchanged buffer(s)
let g:smartq_auto_wipe_emtpy = 1
" Best attempt to prevent exiting the editor when left with an empty modifiable buffer
let g:smartq_no_exit = 0
" Automatically close splits when left with one modifiable buffer
let g:smartq_auto_close_splits = 0

" --- PLUGIN INTEGRATIONS
" When a plugin is disabled, use built-in fallbacks

" Enable Goyo
let g:smartq_goyo_integration = 1
" Enable Zen-mode
let g:smartq_zenmode_integration = 1
```

## SmartQ Quit Prioritization

SmartQ evaluates the conditions below in order and executes only the first
matching action.

1. **Delete** (`bd`) all `diff` buffers. Check: `:set diff?`
2. Handle [Zen-mode](https://github.com/folke/zen-mode.nvim) buffers.
3. Handle [Goyo](https://github.com/junegunn/goyo.vim) buffers.
4. **Quit** (`q`)
   - `smartq_q_filetypes` or `smartq_q_buftypes`
   - `nomodifiable` or `readonly` window
   - Exceptions: `smartq_exclude_filetypes`, `smartq_exclude_buftypes`,
     empty `filetype`, and empty `buftype`
5. On the final buffer
   - **Close** (`close!`) all `modifiable` windows, or **Quit all** (`qa`)
     when the buffer is empty.
6. On the final buffer with `nomodifiable` window(s)
   - **Quit all** (`qa`) when the buffer is empty.
7. **Wipe** (`bw`)
   - `smartq_bw_filetypes`, `smartq_bw_buftypes`, or `terminal` buffer
   - Exceptions: `smartq_exclude_filetypes`, `smartq_exclude_buftypes`,
     empty `filetype`, and empty `buftype`
8. Catch all: **Delete** (`bd`) buffer. Check: `:buffers`

See `diff`, `modifiable`, `filetype`, `buftype`, and `buffers`.


## Credits

- [cespare/vim-sbd](https://github.com/cespare/vim-sbd)
- [moll/vim-bbye](https://github.com/moll/vim-bbye)
- [Asheq/close-buffers.vim](https://github.com/Asheq/close-buffers.vim)
