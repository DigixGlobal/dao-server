FROM ruby:2.5.3
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs vim

RUN mkdir -p /usr/src/dao-server

WORKDIR /usr/src/dao-server
COPY ./Gemfile ./
COPY ./Gemfile.lock ./
RUN bundle install

COPY . ./

RUN ln -nfs /usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 /usr/lib/x86_64-linux-gnu/libssl.so

RUN chmod 755 ./docker-entrypoint.sh
ENTRYPOINT ["/usr/src/dao-server/docker-entrypoint.sh"]

EXPOSE 3005

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3005"]
