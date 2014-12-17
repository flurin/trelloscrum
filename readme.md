# Trello SCRUM card printer

Generates PDF's with (+/-) one page per card with title, body and checklists. Print 4 of them on an A4 for the best action.

## Getting started

1. Create a `config.json`
1. Generate a Trello developer key here: https://trello.com/c/jObnWvl1/25-generating-your-developer-key
1. Generate a Trello member token for your user: https://trello.com/c/fD8ErOzA/26-getting-a-user-token-and-oauth-urls
1. Configure the dev key and member token, and board_id (you can get the board id from the url in Trello) in config.json (see below for format)
1. Run generate.rb! (see below for options)

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
Usage: generate.rb [options] outfile.pdf
        --only-estimated      Wether or not to output only estemates
        --config              Path to config, default is local directory/config.json
        --list                Listname to use
        --filter-title        Regexp to filter on titles, only show's cards matching title
    -h, --help                Display this help message.
```

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