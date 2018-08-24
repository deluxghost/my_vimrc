" Do not modify version
let g:dx_version = "2.0.1"

" System settings
let g:dx_windows = 0
let g:dx_sep = "/"
let g:dx_vim_dir = $HOME . "/.vim/"
let g:dx_exec_ready = 0
if has("win32") || has("win64") || has("win16")
    let g:dx_windows = 1
    let g:dx_sep = "\\"
    let g:dx_vim_dir = $HOME . "\\vimfiles\\"
endif
if executable("git") && executable("curl")
    let g:dx_exec_ready = 1
endif

" Update settings
let g:dx_update_repo = "https://github.com/deluxghost/vimrc"
let g:dx_update_raw = "https://raw.githubusercontent.com/deluxghost/vimrc/master/.vimrc"
let g:dx_dir = g:dx_vim_dir . "dx_vimrc" . g:dx_sep
let g:dx_version_file = g:dx_dir . "vimrc.version"
let g:dx_update_file = g:dx_dir . "vimrc.update"
if !isdirectory(g:dx_dir)
    call mkdir(g:dx_dir, "p")
endif
let g:dx_update = 1
if !empty(glob(g:dx_dir . ".noupdate")) || !empty(glob(g:dx_dir . "_noupdate"))
    let g:dx_update = 0
endif
let g:dx_gvim = 0
if has("gui_running")
    let g:dx_gvim = 1
    set guioptions+=c
    set guioptions-=T
    set guioptions-=m
    set guioptions-=e
endif
let g:dx_vundle = 0

" Use Vim instead of Vi
set nocompatible
" Load Vundle runtime
filetype off
if g:dx_windows
    set runtimepath+=$HOME\vimfiles\bundle\Vundle.vim\
else
    set runtimepath+=~/.vim/bundle/Vundle.vim/
endif
runtime autoload/vundle.vim
let g:dx_need_plugin_install = 0

" Init Vundle and load plugins
function! Start_Vundle()
    if g:dx_windows
        call vundle#begin('$USERPROFILE/vimfiles/bundle/')
    else
        call vundle#begin()
    endif
    let vimrc_plugin_files = [".vim.plugin", "_vim.plugin", ".vimrc.plugin", "_vimrc.plugin"]
    for filename in vimrc_plugin_files
        if filereadable($HOME . g:dx_sep . filename)
            execute "source " . $HOME . g:dx_sep . filename
        endif
    endfor
    unlet vimrc_plugin_files
    call vundle#end()
    let g:dx_vundle = 1
endfunction

" Install Vundle automatically
function! Install_Vundle()
    if !g:dx_exec_ready
        echomsg "Vundle needs git and curl to work."
        echomsg "How to install git and curl on Windows: "
        echomsg "https://github.com/VundleVim/Vundle.vim/wiki/Vundle-for-Windows"
        return
    endif
    let vundle_dir = g:dx_vim_dir . "bundle" . g:dx_sep . "Vundle.vim"
    if !isdirectory(vundle_dir)
        call mkdir(vundle_dir, "p")
    endif
    if g:dx_windows && !g:dx_gvim
        silent execute "!cls"
    endif
    silent execute "!git clone https://github.com/VundleVim/Vundle.vim.git " . vundle_dir
    if v:shell_error
        echomsg "Failed to install: can't clone repo. Please install Vundle manually."
        echomsg "All plugins are disabled."
    else
        echomsg "Vundle has been installed."
        call Write_Plugin()
        call Start_Vundle()
        let g:dx_need_plugin_install = 1
    endif
    unlet vundle_dir
endfunction

" Default plugins
function! Write_Plugin()
    let plugin_list = [
        \"Plugin 'VundleVim/Vundle.vim'",
        \"Plugin 'ervandew/supertab'",
        \"Plugin 'tpope/vim-surround'",
        \"Plugin 'ctrlpvim/ctrlp.vim'",
        \"Plugin 'joshdick/onedark.vim'",
        \"Plugin 'scrooloose/nerdcommenter'",
        \"Plugin 'easymotion/vim-easymotion'",
        \"Plugin 'terryma/vim-multiple-cursors'",
        \"Plugin 'ntpeters/vim-better-whitespace'"
    \]
    if g:dx_windows
        let plugin_file = "_vim.plugin"
    else
        let plugin_file = ".vim.plugin"
    endif
    call writefile(plugin_list, $HOME . g:dx_sep . plugin_file)
    unlet plugin_list
endfunction

function! Enter_Init()
    " Install plugins
    if g:dx_need_plugin_install
        PluginInstall
    endif
    " Color Scheme
    if g:dx_gvim
        silent! colorscheme evening
        silent! colorscheme onedark
    else
        silent! colorscheme default
    endif
    call Highlight_Fix()
    " Check vimrc update
    if g:dx_exec_ready
        if !empty(g:dx_new_version) && g:dx_new_version != g:dx_version
            echo "New vimrc found: " . g:dx_new_version . " | Your version: " . g:dx_version . "\n" . g:dx_update_repo
        endif
        let update_cmd = "curl -s -o \"" . g:dx_update_file . "\" \"" . g:dx_update_raw . "\""
        if g:dx_windows
            silent execute "!start /b " . update_cmd
        else
            let update_cmd = "!" . update_cmd . " &"
            silent execute update_cmd | redraw!
        endif
        unlet update_cmd
    else
        echo "Vundle needs git and curl to work.\n\nHow to install git and curl on Windows: \nhttps://github.com/VundleVim/Vundle.vim/wiki/Vundle-for-Windows"
    endif
endfunction

" Check and install Vundle on first time
if exists("*vundle#rc")
    call Start_Vundle()
    " Check vimrc version and update plugins
    silent! let vimrc_file_version = readfile(g:dx_version_file, "", 1)
    let vimrc_old_version = (len(vimrc_file_version) > 0 ? vimrc_file_version[0] : "")
    if vimrc_old_version != g:dx_version
        let g:dx_need_plugin_install = 1
    endif
    unlet vimrc_file_version
else
    call Install_Vundle()
endif
call writefile([g:dx_version], g:dx_version_file)

" Check vimrc update
if g:dx_exec_ready
    silent! let vimrc_file_update = readfile(g:dx_update_file, "", 3)
    let vimrc_new = ""
    for line in vimrc_file_update
        let vermatch = matchstr(line, '^let g:dx_version = "\zs.\{-}\ze"$')
        if !empty(vermatch)
            let vimrc_new = vermatch
        endif
        unlet vermatch
    endfor
    let g:dx_new_version = vimrc_new
    unlet vimrc_file_update
    unlet vimrc_new
endif

" Highlight patching
function! Highlight_Fix()
    if !g:dx_gvim && (g:colors_name == "default" || g:colors_name == "evening")
        highlight ColorColumn ctermbg=Grey ctermfg=DarkBlue
        highlight CursorLine cterm=none ctermbg=DarkBlue ctermfg=White
    endif
endfunction

" Detect file encoding automatically
set fileencodings=utf-8,gbk,gb18030,utf-16le
" Detect file format automatically
set fileformats=unix,dos,mac
" Remove unused buffer
set nohidden
" How many lines of history can vim remember
set history=750
" Disable welcome message
set shortmess=atI
" Ensure backspace work
set backspace=indent,eol,start
" Set width of tab to 4
set tabstop=4
set softtabstop=4
set shiftwidth=4
" Use spaces instead of tabs
set expandtab
" Smarter tab
set smarttab
" Don't break line
set textwidth=0
" Reload when a file is changed outside
set autoread
" Enable auto indent
set autoindent
" Show line number
set number
" Show command at the last line
set showcmd
" Show search matches dynamically
set incsearch
" Highlight search results
set hlsearch
" Ignore case when searching
set ignorecase
" Only ignore case when pattern contains no upper case
set smartcase
" Show matching brackets
set showmatch
" Highlight current line
set cursorline
" Auto completion of command-line
set wildmenu
" Ignore compiled and resource files
set wildignore=*.a,*.o,*.so,*~,*.pyc,*.class
set wildignore+=*.bak,*.swp,*.swo
set wildignore+=*.bmp,*.jpg,*.jpeg,*.gif,*.png,*.pdf
" Ignore project directories
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
" Show tab bar
set showtabline=2
" Show status bar
set laststatus=2

" Enable syntax highlighting
syntax on
" Enable filetype plugins and indents
filetype plugin indent on

" Set the format of status bar
set statusline=
"  Filename
set statusline+=%<%F
"  Filetype, encoding and file format (line-ending)
set statusline+=\ %{'['.(&filetype!=''?&filetype:'none').']'}
set statusline+=\ %{''.(&fenc!=''?&fenc:&enc).''}%{(&bomb?\",bom\":\"\")}
set statusline+=\ %{&fileformat}
"  Line and column number
set statusline+=\ %=\ Ln\ %l/%L\ Col\ %c
"  Modified, readonly, preview and ruler
set statusline+=\ %m%r%w\ %P\ %0*
" Avoid unexpected searching highlight
nohlsearch

" Set map leader
let mapleader = ","
let g:mapleader = ","
" General mapping
"  Go PasteMode
nmap <silent> <leader>p :call PasteMode()<CR>
"  Go PasteMode at newline
nmap <silent> <leader>op :normal o<CR>:call PasteMode()<CR>
nmap <silent> <leader>OP :normal O<CR>:call PasteMode()<CR>
"  Switch tabs
nnoremap <C-Tab> gt
nnoremap <C-S-Tab> gT
"  Arrow keys moving in wrapped lines
inoremap <Down> <C-o>gj
inoremap <Up> <C-o>gk

" Declare commands and auto commands
"  Do after vim loaded
autocmd! VimEnter * call Enter_Init()
"  Disable PasteMode automatically
autocmd! InsertLeave * setlocal nopaste
"  Fix highlight automatically
autocmd! ColorScheme * call Highlight_Fix()
"  Reload VIMRC automatically
autocmd! BufWritePost $MYVIMRC source %
"  Jump to the last edit position
autocmd! BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif
"  Syntax for .vim.plugin and .vimrc2
autocmd! BufNewFile,BufReadPost,BufNew .vim.plugin,_vim.plugin,.vimrc.plugin,_vimrc.plugin setl ft=vim
autocmd! BufNewFile,BufReadPost,BufNew .vimrc2,_vimrc2,.vimrc.user,_vimrc.user setl ft=vim
"  Show my vimrc version
command! Ver echo g:dx_version
"  Tell you the time
command! Time echo strftime("Time: %F %a %T")

" Enter PasteMode (:set paste)
function! PasteMode()
    set paste
    startinsert
endfunction

" If Vundle loaded successfully
if g:dx_vundle
    " Vundle mappings
    nmap <leader><leader>p :PluginInstall<CR>
    nmap <leader><leader>pi :PluginInstall<CR>
    nmap <leader><leader>pc :PluginClean<CR>
    nmap <leader><leader>pl :PluginList<CR>
    nmap <leader><leader>pu :PluginUpdate<CR>
    " Clear Whitespace
    nmap <leader><space><space> :StripWhitespace<CR>:echo "Trailing Whitespaces Cleared!"<CR>
    " CtrlP Settings
    let g:ctrlp_map = '<C-p>'
    let g:ctrlp_cmd = 'CtrlP'
    let g:ctrlp_working_path_mode = 'ra'
    let g:ctrlp_custom_ignore = {
        \'dir':  '\v[\/]\.(git|hg|svn|rvm|DS_Store)$',
        \'file': '\v\.(exe|so|dll|zip|tar|tar.gz|pyc)$'
    \}
endif

" Load user settings
let vimrc_name = [".vimrc2", "_vimrc2", ".vimrc.user", "_vimrc.user"]
for name in vimrc_name
    if filereadable($HOME . g:dx_sep . name)
        execute "source " . $HOME . g:dx_sep . name
    endif
endfor
unlet vimrc_name
