# valkyrie

Transfer data between databases

## Installation

    gem install valkyrie

## Usage

    $ valkyrie mysql://localhost/myapp_development postgres://localhost/myapp_development
    Transferring 5 tables:
    delayed_jobs:   100% |=========================================| Time: 00:00:00
    messages:       100% |=========================================| Time: 00:00:00
    participants:   100% |=========================================| Time: 00:00:02
    schema_migrati: 100% |=========================================| Time: 00:00:00
    settings:       100% |=========================================| Time: 00:00:00

## License

    MIT
