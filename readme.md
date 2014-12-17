# Trello SCRUM card printer

Generates PDF's with (+/-) one page per card with title, body and checklists. Print 4 of them on an A4 for the best action.

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