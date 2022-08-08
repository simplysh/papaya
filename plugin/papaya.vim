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

  for error in s:errors
    if error.filename ==# current_path
      let padding = join(map(range(error.col - 1), {-> ' '}), '')

      call prop_add(error.lnum, 0, { 'type': 'papaya_hint', 'text': padding . '└─' . error.text, 'text_align': 'below' })
    endif
  endfor

  let b:papaya_decorated = 1
endfunction

function! s:to_quick_fix(text)
  let [all, source, line, col, message; other] = matchlist(a:text, g:papaya_error_pattern)
  return { 'filename': source, 'lnum': line, 'col': col, 'text': message }
endfunction

function! s:make()
  echo 'Running...'

  let result = system(&makeprg)
  execute "normal! :\<backspace>\<esc>"

  let lines = split(result, '[\x0]')
  call filter(lines, {index, value -> s:is_error_message(value)})

  if !len(lines)
    return
  endif

  call map(lines, {index, value -> s:to_quick_fix(value)})

  let s:errors = lines
  call setqflist(lines, 'r')
  execute "cfirst"

  if s:virtual_is_supported
    call s:decorate_current_buffer()
  endif
endfunction

if s:virtual_is_supported
  autocmd BufEnter * :call s:decorate_current_buffer()
  autocmd BufLeave * :unlet! b:papaya_decorated
endif

command! -nargs=0 -bar PapayaMake call s:make()

