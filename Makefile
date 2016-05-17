.DEFAULT_GOAL = start

PID = ./tmp/pids/puma.pid

start: setup start_puma

pumap: setupp
	puma -e production -C config/puma.rb -d

start_puma:
	puma -e development -C config/puma.rb

unicornp:
	bundle exec unicorn -E production -c config/unicorn.conf.rb -D

# @see https://gist.github.com/tachesimazzoca/3891036
restart_puma:
	-kill -s USR2 `cat $(PID)`

stop_puma:
	-kill -s TERM `cat $(PID)`

setup:
	rake db:drop db:create db:migrate db:seed

setupp:
	DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RAILS_ENV=production rake db:drop db:create db:migrate db:seed

test_prepare:
	rake db:test:prepare
	rake db:test:load

c:
	rails c

resquep:
	RAILS_ENV=production QUEUE=* rake environment resque:work

resque:
	RAILS_ENV=development QUEUE=* rake environment resque:work

sidekiq:
	bundle exec sidekiq -e development -q default -L log/sidekiq.log -C config/sidekiq.yml -d

sidekiqp:
	bundle exec sidekiq -e production -q default -L log/sidekiq.log -C config/sidekiq.yml -d
