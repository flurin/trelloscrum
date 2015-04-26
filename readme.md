# Trello SCRUM card printer

Generates PDF's with (+/-) one page per card with title, body and checklists. Print 4 of them on an A4 for the best action.

## Getting started

1. Create a `config.json` by running `trelloscrum setup`. For more information on how to set up everything run `trelloscrum help setup`
1. Run

## Card format

This is the trello card format we use

```
(STORYPOINTS) [CLIENT] TITLE
BODY

Checklist
[] item
[] item
```

## Commandline options

```
Commands:
  trelloscrum help [COMMAND]                                      # Describe available commands or one specific command
  trelloscrum pdf OUTFILE                                         # generate PDF for cards
  trelloscrum setup DEVELOPER_PUBLIC_KEY MEMBER_TOKEN [BOARD_ID]  # config trello

Options:
      [--config=CONFIG]           # Path to config, default is local directory/config.json
                                  # Default: ./config.json
  v, [--verbose], [--no-verbose]  # Verbose output
```

For more options run `trelloscrum help [COMMAND]`

## Config.json

```
{
  "developer_public_key" : "",
  "member_token" : "",
  "list_name" : "",
  "board_id" : ""
}
```

## License

- All code and documentation is licesned under the MIT license:
  - http://opensource.org/licenses/mit-license.html
- The Font Awesome font is licensed under the SIL OFL 1.1:
  - http://scripts.sil.org/OFL