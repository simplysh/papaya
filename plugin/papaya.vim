if exists("g:loaded_papaya")
  finish
endif
let g:loaded_papaya = 1

if !exists('g:papaya_error_pattern')
  let g:papaya_error_pattern = '\v^(.*):(\d+):(\d+):\serror:\s(.*)$'
endif

let s:virtual_is_supported = v:version >= 900 && has("patch167")

if s:virtual_is_supported
  call prop_type_add( 'papaya_hint', { 'highlight': 'ErrorMsg' })
endif

function! s:is_error_message(text)
  return a:text =~ g:papaya_error_pattern
endfunction

function! s:to_quick_fix(text)
  let [all, source, line, col, message; other] = matchlist(a:text, g:papaya_error_pattern)

  if (s:virtual_is_supported)
    let padding = join(map(range(col - 1), {-> ' '}), '')
    call prop_add(line, 0, { 'type': 'papaya_hint', 'text': padding . '└─' . message, 'text_align': 'below' })
  endif

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

  call setqflist(lines, 'r')
  execute "cfirst"
endfunction

command! -nargs=0 -bar PapayaMake call s:make()

