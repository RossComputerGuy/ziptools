# ziptools

Modern zip &amp; unzip replacements

## Why ziptools?

Ziptools is a lightweight cross platform CLI for managing zip files. For many years, `zip` and `unzip` has existed and was provided by info-zip.org. However, it's been lacking in updates and is known for having many CVE's tied to it. Ziptools fixes that by providing a `zip` and `unzip` compatible set of commands which are implemented using Zig. Zig, unlike C, is a more modern language and deals better with buffer overflows and similar kinds of exploits.

## Replacing `zip` & `unzip`

By default, ziptools installs a `ziptools` command with `zip` and `unzip` subcommands. If you're looking to replace the legacy tools with ziptools, the only requirement is to link `zip` and `unzip` to the `ziptools` command like so:

```sh
$ ln -s /usr/bin/ziptools /usr/bin/zip
$ ln -s /usr/bin/ziptools /usr/bin/unzip
```

## Building ziptools

The only requirement to building ziptools is Zig 0.15 and running `zig build`.
