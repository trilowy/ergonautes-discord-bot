# Ergonautes Discord Bot

Discord commands to invoque on Ergonautes Discord to get help responses on
frequently asked questions.

[Developer informations here](./DEVELOPER_GUIDE.md).


## Commands

### Documentation

Documentation command `/doc` is available to any Discord user. Its only
parameter is the name of the documentation file, keep it under 32 char.

It auto-discovers documentation files at compile-time in `doc/` directory and
embed them in the server binary.

The file should be in Markdown (`.md` extension).

Do not limit lines length in these files as Discord will render these line
returns.
