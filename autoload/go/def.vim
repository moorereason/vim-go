if !exists("g:go_guru_bin")
	let g:go_guru_bin = "guru"
endif

if go#vimproc#has_vimproc()
	let s:vim_system = get(g:, 'gocomplete#system_function', 'vimproc#system2')
else
	let s:vim_system = get(g:, 'gocomplete#system_function', 'system')
endif

fu! s:system(str, ...)
	return call(s:vim_system, [a:str] + a:000)
endf

function! go#def#Jump(mode)
	let bin_path = go#path#CheckBinPath(g:go_guru_bin)
	if empty(bin_path)
		return
	endif

	let old_gopath = $GOPATH
	let $GOPATH = go#path#Detect()

	let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
	let command = printf("%s definition %s:#%s", bin_path, shellescape(fname), go#util#OffsetCursor())

	let out = s:system(command)

	call s:jump_to_declaration(out, a:mode)
	let $GOPATH = old_gopath
endfunction

function! s:jump_to_declaration(out, mode)
	let old_errorformat = &errorformat
	let &errorformat = "%f:%l:%c:\ %m"

	let parts = split(a:out, ':')

	" parts[0] contains filename
	let fileName = parts[0]

	" put the error format into location list so we can jump automatically to it
	lgetexpr a:out

	" needed for restoring back user setting this is because there are two
	" modes of switchbuf which we need based on the split mode
	let old_switchbuf = &switchbuf

	if a:mode == "tab"
		let &switchbuf = "usetab"

		if bufloaded(fileName) == 0
			tab split
		endif
	else
		if a:mode  == "split"
			split
		elseif a:mode == "vsplit"
			vsplit
		endif
	endif

	" jump to file now
	sil ll 1
	normal! zz

	let &switchbuf = old_switchbuf
	let &errorformat = old_errorformat
endfunction
