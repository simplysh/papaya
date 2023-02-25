if exists("g:papaya_loaded")
  finish
endif
let g:papaya_loaded = 1

if !exists('g:papaya_error_pattern')
  let g:papaya_error_pattern = '\v^(.*):(\d+):(\d+):\s%(fatal\s)?error:\s(.*)$'
endif

if !exists('g:papaya_make')
  let g:papaya_make = &makeprg
endif

let s:virtual_is_supported = v:version >= 900 && has("patch246")
let s:errors = []
let s:output = []

if s:virtual_is_supported
  call prop_type_add('papaya_hint', { 'highlight': 'ErrorMsg' })
endif

function! s:is_error_message(text)
  let matched = a:text =~ g:papaya_error_pattern

  if exists("g:papaya_debug")
    echom a:text . ' (' . matched . ')'
  endif

  return matched
endfunction

function! s:smart_sort(a, b)
  if (a:a.filename !=# a:b.filename)
    return a:a.filename < a:b.filename ? -1 : a:a.filename > a:b.filename ? 1 : 0
  endif

  if (a:a.lnum !=# a:b.lnum)
    return a:a.lnum - a:b.lnum
  endif

  if (a:a.col !=# a:b.col)
    return a:b.col - a:a.col
  endif

  return 0
endfunction

function! s:decorate_current_buffer()
  if exists("b:papaya_decorated")
    return
  endif

  let current_path = substitute(expand("%:."), "\\", "/", "g")
  let to_add = []
  let errors = deepcopy(s:errors)

  " add pipes for multiple errors on same line
  for error in errors
    if error.filename ==# current_path
      let padding = map(range(error.col - 1), {-> ' '})

      " go through inner messages and update symbols
      for hint in to_add
        if hint.lnum ==# error.lnum
          if error.col - 1 < len(hint.padding)
            let hint.padding[error.col - 1] = '│'
          endif

          if error.col ==# hint.col
            let hint.leader = '├─'
          endif
        endif
      endfor

      call add(to_add, { 'lnum': error.lnum, 'col': error.col, 'leader': '└─', 'text': error.text, 'padding': padding })
    endif
  endfor

  for hint in to_add
    call prop_add(hint.lnum, 0, { 'type': 'papaya_hint', 'text': join(hint.padding, '') . hint.leader . hint.text, 'text_align': 'below' })
  endfor

  let b:papaya_decorated = 1
endfunction

function! s:clear_decorations()
  call prop_remove({ 'type': 'papaya_hint', 'all': 1 })
  unlet! b:papaya_decorated
endfunction

function! s:to_quick_fix(text)
  let [all, source, line, col, message; other] = matchlist(a:text, g:papaya_error_pattern)
  return { 'filename': source, 'lnum': str2nr(line, 10), 'col': str2nr(col, 10), 'text': message }
endfunction

function! s:show_output()
  silent! noautocmd execute 'pedit Complier Output'

  silent! wincmd P
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile

  call append(0, s:output)
  setlocal readonly
endfunction

function! s:make()
  echo 'Running...'

  call setqflist([], 'r')
  let s:errors = []
  let s:output = []
  if s:virtual_is_supported
    call s:clear_decorations()
  endif

  silent let result = system(g:papaya_make)
  execute "normal! :\<backspace>\<esc>"

  let lines = split(result, '[\x0]')
  let s:output = deepcopy(lines)
  call filter(lines, {index, value -> s:is_error_message(value)})

  if !len(lines)
    return
  endif

  call sort(uniq(sort(map(lines, {index, value -> s:to_quick_fix(value)}))), function('s:smart_sort'))

  let s:errors = lines
  call setqflist([], 'r', { 'title': 'Compiler Errors' })
  call setqflist(lines, 'a')
  execute "silent! cfirst"

  if s:virtual_is_supported
    call s:decorate_current_buffer()
  endif
endfunction

if s:virtual_is_supported
  autocmd BufRead * :call s:decorate_current_buffer()
  autocmd BufLeave * :unlet! b:papaya_decorated
endif

command! -nargs=0 -bar PapayaMake call s:make()
command! -nargs=0 -bar PapayaClear call s:clear_decorations()
command! -nargs=0 -bar PapayaOutput call s:show_output()

