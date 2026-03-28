# FCM Digital - Ruby Technical challenge

Ruby library to transform user reservations into a easy-to-follow itinerary.

## Setup

### With Docker

- Install [Docker](https://docs.docker.com/engine/install/).
- Build the image with `docker build -t travel_manager .`.
- Run the project with `docker run --rm -e BASED=SVQ travel_manager`. 

The default input is input.txt, which is copied from the root to the image. You can change it by editing the [Dockerfile](./Dockerfile).

### Manual setup

- Install [Ruby 3.4.7](https://www.ruby-lang.org/es/downloads/) (I suggest using [rbenv](https://github.com/rbenv/rbenv) or similar). Not tested in other versions.
- Install [Bundler](https://bundler.io/).
- Install the library with `bundler install`.
- Run the project with `BASED=SVG bundle exec ruby main.rb input.txt`.

## YARD documentation

This project has been documented using [YARD](https://yardoc.org/). To preview the documentation just run `bin/yard server` and open the given url.

## Documentation

- [Requirements](/docs/requirimients.md): challenge requirements.
- [AI usage registry](/docs/ai.md): as asked in the interview, I registered all my AI usage for transparency.
- [Decision Registry](/docs/decisions.md): reasonings and explanation behind architectural and implementation decisions.