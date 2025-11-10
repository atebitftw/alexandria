# Alexandria

A command-line utility for generating and consolidating Dart documentation from multiple projects into a single, easy-to-navigate web page.

## Features

-   Generates documentation using `dart doc`.
-   Consolidates docs from multiple projects into one output directory.
-   Creates a master index page for easy navigation between project docs.
-   Intelligently skips doc generation for projects whose versions have not changed.

## Installation

To use Alexandria as a command-line tool, you first need to activate it using `dart pub`.
```bash
dart pub global activate --source git git@github.com:atebitftw/alexandria.git
```

This will compile the utility and make the `alexandria` command available globally in your terminal.

## Usage

1.  Create an `alexandria_config.json` file.
2.  Configure the file to point to your projects (see Configuration below).
3.  Run the `alexandria` command.

```bash
alexandria
```

The utility will generate the documentation into the specified output directory and create a master `index.html` for navigation.

## Options

| Flag | Abbreviation | Description | Default |
|---|---|---|---|
| `--config` | `-c` | Path to the alexandria_config.json file. | `alexandria_config.json` |
| `--help` | `-h` | Displays this help information. | |
| `--version` | | Displays the application version. | |
| `--verbose` | `-o` | Shows verbose output from dart doc. | |

## Configuration

The `alexandria` utility is controlled by a configuration file. By default, it looks for `alexandria_config.json` in the current directory, but you can specify a different path via the command line.

The configuration is a JSON array with a single object that has the following fields:

-   `output_dir` (string): The absolute or relative path to the directory where all documentation will be generated. The `~` character can be used for the user's home directory.
-   `projects_root` (string): The absolute or relative path to a root directory that contains your Dart projects. The `~` character can be used.
-   `projects` (array of strings): A list of project paths relative to the `projects_root`.

### Example `alexandria_config.json`

```json
[
    {
        "output_dir": "~/dev/docs",
        "projects_root": "~/dev/projects",
        "projects": [
            "some_dart_side_project",
            "my_app/core_logic",
            "my_app/ui_components"
        ]
    }
]
```

In this example:
-   Documentation will be generated in `~/dev/docs`.
-   The tool will look for projects inside `~/dev/projects`.
-   It will process three projects located at:
    -   `~/dev/projects/some_dart_side_project`
    -   `~/dev/projects/my_app/core_logic`
    -   `~/dev/projects/my_app/ui_components`
-   The final documentation for `some-dart-side-project` will be in `~/dev/docs/some_dart_side_project/index.html`.

## Web Page Table Of Contents
The utility will generate a static html web page in the root of the `output_dir` directory.  This page will display a list of all the projects for easy navigation to their respective docs.
