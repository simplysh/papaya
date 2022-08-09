if exists("g:loaded_papaya")
  finish
endif
let g:loaded_papaya = 1

if !exists('g:papaya_error_pattern')
  let g:papaya_error_pattern = '\v^(.*):(\d+):(\d+):\serror:\s(.*)$'
endif

let s:virtual_is_supported = v:version >= 900 && has("patch167")
let s:errors = []

if s:virtual_is_supported
  call prop_type_add('papaya_hint', { 'highlight': 'ErrorMsg' })
endif

function! s:is_error_message(text)
  return a:text =~ g:papaya_error_pattern
endfunction

function! s:decorate_current_buffer()
  if exists("b:papaya_decorated")
    return
  endif

  let current_path = expand("%")
  let to_add = []

  for error in s:errors
    if error.filename ==# current_path
      let padding = map(range(error.col - 1), {-> ' '})

      for hint in to_add
        let padding[hint.col - 1] = '│'
      endfor

      call add(to_add, { 'lnum': error.lnum, 'col': error.col, 'text': '└─' . error.text, 'padding': padding })
    endif
  endfor

  for hint in to_add
    call prop_add(hint.lnum, 0, { 'type': 'papaya_hint', 'text': join(hint.padding, '') . hint.text, 'text_align': 'below' })
  endfor

  let b:papaya_decorated = 1
endfunction

function! s:clear_decorations()
  call prop_remove({ 'type': 'papaya_hint', 'all': 1 })
  unlet! b:papaya_decorated
endfunction

function! s:to_quick_fix(text)
  let [all, source, line, col, message; other] = matchlist(a:text, g:papaya_error_pattern)
  return { 'filename': source, 'lnum': line, 'col': col, 'text': message }
endfunction

function! s:make()
  echo 'Running...'

  call setqflist([], 'r')
  let s:errors = []
  if s:virtual_is_supported
    call s:clear_decorations()
  endif

  let result = system(&makeprg)
  execute "normal! :\<backspace>\<esc>"

  let lines = split(result, '[\x0]')
  call filter(lines, {index, value -> s:is_error_message(value)})

  if !len(lines)
    return
  endif

  call map(lines, {index, value -> s:to_quick_fix(value)})

  let s:errors = lines
  call setqflist([], 'r', { 'title': 'compiler errors' })
  call setqflist(lines, 'a')
  execute "cfirst"

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

