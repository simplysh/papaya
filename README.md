# papaya
Alternative Vim compiler support

![papaya screenshot](papaya.png)

### Motivation

papaya is a simple plugin to streamline running the C compiler from within Vim.

## How it works
Papaya will use the value of your `makeprg` variable to run the compiler.
Alternatively, you can set the command using:

```
set g:papaya_make=command
```

If there are compilation errors, papaya will annotate the current buffer using virtual text (only works with Vim 9).

Papaya also populates the quick fix list.

## Commands

To run papaya, use:
```
:PapayaMake
```
To see the original compilation output, use:

```
:PapayaOutput
```

To clear virtual text annotations, use:
```
:PapayaClear
```
