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


### Boost a contributor

Only the user with the Discord permission to manage roles can call the
`/contrib` command followed by Discord username, or right click on the user to
do so.

It rewards this user with the special role `Contrib’` during 2 weeks. At the
end of theses 2 weeks (if it is not prolonged by another call of this command)
it removes the role.

The moderator uses this command when they judges the user helped the community
or projects in a meaningful way.
