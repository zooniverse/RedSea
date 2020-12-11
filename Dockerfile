FROM ruby:2.6

WORKDIR /app

ADD ./Gemfile /app/
ADD ./Gemfile.lock /app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1` \
    && bundle install

ARG REVISION=''
ENV REVISION=$REVISION

ADD ./ /app

CMD ["bundle", "exec", "puma", "-C", "puma.rb"]