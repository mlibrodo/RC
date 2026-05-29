set sm

set ai				" autoindent

set ignorecase

set number

set scrolloff=5

set nocompatible              " be iMproved, required
filetype off                  " required

" http://superuser.com/questions/246641/vim-completion-always-suppress-the-newline-after-i-select-a-suggestion-with-th
" dont skip line when using Ctrl-N
noremap pumvisible() ? "\" : " "

nnoremap gr :grep --exclude-dir="target" -I -F -i -r <cword> *<CR>
nnoremap GR :grep --exclude-dir="target" -I -F -r <cword> *<CR>
nnoremap gR :grep --exclude-dir="target" -I -r '\b<cword>\b' *<CR>

au WinLeave * set nocursorline "nocursorcolumn
au WinEnter * set cursorline "cursorcolumn
set cursorline " cursorcolumn

" Set cursorline colors
highlight CursorLine ctermbg=235
" " Set color of number column on cursorline
highlight CursorLineNR ctermbg=235 ctermfg=white

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
"Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
" Scala plugins
Plugin 'derekwyatt/vim-scala'

Plugin 'scrooloose/nerdtree.git'

Plugin 'kien/ctrlp.vim'

Plugin 'fatih/vim-go'

call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

syntax on
let java_highlight_all=1

let java_highlight_functions="style"

:let java_allow_cpp_keywords=1


"set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" Show whitespace characters
set list
set listchars=space:·,tab:→\ ,trail:•,eol:¬

set ls=2 " Always show status line
if has('statusline')
   " Status line detail:
   " %f     file path
   " %y     file type between braces (if defined)
   " %([%R%M]%)   read-only, modified and modifiable flags between braces
   " %{'!'[&ff=='default_file_format']}
   "        shows a '!' if the file format is not the platform
   "        default
   " %{'$'[!&list]}  shows a '*' if in list mode
   " %{'~'[&pm=='']} shows a '~' if in patchmode
   " (%{synIDattr(synID(line('.'),col('.'),0),'name')})
   "        only for debug : display the current syntax item name
   " %=     right-align following items
   " #%n    buffer number
   " %l/%L,%c%V   line number, total number of lines, and column number
   function SetStatusLineStyle()
      if &stl == '' || &stl =~ 'synID'
         let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]}%{'~'[&pm=='']}%=#%n %l/%L,%c%V "
      else
         let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]} (%{synIDattr(synID(line('.'),col('.'),0),'name')})%=#%n %l/%L,%c%V "
      endif
   endfunc
   " Switch between the normal and vim-debug modes in the status line
   nmap _ds :call SetStatusLineStyle()<CR>
   call SetStatusLineStyle()
   " Window title
   if has('title')
      set titlestring=%t%(\ [%R%M]%)
   endif
endif

function! DoPrettyXML()
  " save the filetype so we can restore it later
  let l:origft = &ft
  set ft=
  " delete the xml header if it exists. This will
  " permit us to surround the document with fake tags
  " without creating invalid xml.
  1s/<?xml .*?>//e
  " insert fake tags around the entire document.
  " This will permit us to pretty-format excerpts of
  " XML that may contain multiple top-level elements.
  0put ='<PrettyXML>'
  $put ='</PrettyXML>'
  silent %!xmllint --format -
  " xmllint will insert an <?xml?> header. it's easy enough to delete
  " if you don't want it.
  " delete the fake tags
  2d
  $d
  " restore the 'normal' indentation, which is one extra level
  " too deep due to the extra tags we wrapped around the document.
  silent %<
  " back to home
  1
  " restore the filetype
  exe "set ft=" . l:origft
    endfunction
command! PrettyXML call DoPrettyXML()

"Nerdtree opens during start
"autocmd vimenter * NERDTree
"Close NERDTree if it is the last open buffer
"autocmd WinEnter * call s:CloseIfOnlyNerdTreeLeft()
"
"" Close all open buffers on entering a window if the only
" buffer that's left is the NERDTree buffer
"function! s:CloseIfOnlyNerdTreeLeft()
"	if exists("t:NERDTreeBufName")
"		if bufwinnr(t:NERDTreeBufName) != -1
"			if winnr("$") == 1
"				q
"			endif
"		endif
"	endif
"endfunction

" NERDTree keybindings
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>


"CTRL=P configurations
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$|target',
  \ 'file': '\v\.(exe|so|dll|class)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }

" Auto-reload files changed outside Vim
set autoread
" Trigger checktime on focus/buffer/idle events so autoread actually fires
" (skip while in command-line mode to avoid clobbering it)
au FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() !~ '\c\v^c' | checktime | endif

" Enable terminal focus reporting so FocusGained/FocusLost fire in terminal Vim
" (requires `set -g focus-events on` in ~/.tmux.conf when running under tmux)
if !has('gui_running')
  set t_ti+=[?1004h
  set t_te+=[?1004l
endif

  " ===========================================================
  " Cheatsheet — quick reminders. Shown on startup (no file)
  " or any time via <leader>? (leader is \ by default).
  " ===========================================================

  function! ShowCheatsheet()
    botright new
    setlocal buftype=nofile bufhidden=wipe noswapfile nowrap
    let lines = [
          \ '=============================================================',
          \ '                    VIM QUICK REFERENCE',
          \ '=============================================================',
          \ '',
          \ '  CONCEPTS  (tab > window > buffer)',
          \ '    buffer    in-memory file contents (one per opened file)',
          \ '    window    a viewport showing one buffer (a "split")',
          \ '    tab       a layout of one or more windows  (:tabnew)',
          \ '    note: closing a window does NOT delete its buffer (:bd does)',
          \ '',
          \ '  FILES & BUFFERS',
          \ '    :e <file>           open file (becomes a new buffer)',
          \ '    :w                  save  (:wq or :x  save+quit)',
          \ '    :q   :qa   :q!      quit / quit all / force quit',
          \ '    Ctrl-g              show filename & line/col info',
          \ '    :ls                 list open buffers',
          \ '    :b <num|name>       switch to buffer by number or name',
          \ '    :bn   :bp           next / previous buffer',
          \ '    :bd                 delete (close) current buffer',
          \ '',
          \ '  WINDOWS / SPLITS  (one window = one viewport on a buffer)',
          \ '    :sp   Ctrl-w s      horizontal split',
          \ '    :vsp  Ctrl-w v      vertical split',
          \ '    Ctrl-w h/j/k/l      move between splits',
          \ '    Ctrl-w c   :close   close current split (buffer stays)',
          \ '    Ctrl-w o            keep only current split',
          \ '    Ctrl-w =            equalize split sizes',
          \ '    Ctrl-w + / -        taller / shorter',
          \ '    Ctrl-w > / <        wider / narrower',
          \ '',
          \ '  TABS  (a tab holds its own set of windows)',
          \ '    :tabnew <file>      open file in a new tab',
          \ '    gt   gT             next / previous tab',
          \ '    :tabc               close current tab',
          \ '    :tabs               list all tabs and their windows',
          \ '',
          \ '  NERDTREE',
          \ '    Ctrl-t              toggle NerdTree',
          \ '    Ctrl-n              open NerdTree',
          \ '    Ctrl-f              find current file in tree',
          \ '',
          \ '  SEARCH / REPLACE',
          \ '    /pattern            search forward  (n next, N prev)',
          \ '    ?pattern            search backward',
          \ '    *                   search word under cursor',
          \ '    :%s/old/new/g       replace all in file',
          \ '    :%s/old/new/gc      replace all with confirm',
          \ '    :s/old/new/g        replace all in current line',
          \ '',
          \ '  FIND / DELETE / YANK TO CHAR  (cursor on "|"  |hello world)',
          \ '    fo / Fo             jump fwd / back to "o"  (lands ON o)',
          \ '    to / To             jump fwd / back to "o"  (lands BEFORE/AFTER o)',
          \ '    dto                 delete up to "o"        ( -> |o world  )',
          \ '    dfo                 delete through "o"      ( -> | world   )',
          \ '    yto                 yank up to "o"          ( yanks "hell"  )',
          \ '    yfo                 yank through "o"        ( yanks "hello" )',
          \ '    ;  /  ,             repeat last f/t  forward / backward',
          \ '',
          \ '  COPY / PASTE  (yank = copy in vim-speak)',
          \ '    yy / yw / y$        yank line / word / to end of line',
          \ '    p / P               paste after / before cursor',
          \ '    "+y    "+p          system clipboard yank / paste',
          \ '    v / V / Ctrl-v      visual char / line / block',
          \ '                        then y to yank, d to cut',
          \ '',
          \ '  DISPLAY TOGGLES',
          \ '    :set list!          toggle whitespace chars (·, →, ¬)',
          \ '    <leader>l           same, as a shortcut',
          \ '    :set wrap!          toggle line wrap',
          \ '    :set number!        toggle line numbers',
          \ '',
          \ '  RELOAD CONFIG',
          \ '    :so $MYVIMRC        reload ~/.vimrc in current session',
          \ '    :PluginInstall      install any newly-added Vundle plugins',
          \ '',
          \ '  THIS CHEATSHEET',
          \ '    <leader>?           show this any time',
          \ '    :h <topic>          full help on any topic',
          \ '',
          \ '=============================================================',
          \ '  Press  q  to close this window.',
          \ '=============================================================',
          \ ]
    call setline(1, lines)
    setlocal nomodifiable
    setlocal filetype=cheatsheet
    nnoremap <buffer> q :close<CR>
    nnoremap <buffer> <Esc> :close<CR>
  endfunction

" Show on Vim startup when no file was opened
autocmd VimEnter * if argc() == 0 | call ShowCheatsheet() | endif

" Show on demand
nnoremap <leader>? :call ShowCheatsheet()<CR>

" Toggle whitespace visualization
nnoremap <leader>l :set list!<CR>


" Machine-specific overrides (not tracked in git)
if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
