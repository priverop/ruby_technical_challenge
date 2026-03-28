# https://hub.docker.com/_/ruby
FROM ruby:3.4.7

WORKDIR /usr/src/app

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY lib ./lib
COPY main.rb input.txt ./

ENV BASED=SVQ

ENTRYPOINT ["bundle", "exec", "ruby", "/usr/src/app/main.rb"]
CMD ["/usr/src/app/input.txt"]
