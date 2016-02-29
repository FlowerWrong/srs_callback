.DEFAULT_GOAL = start

PID = ./tmp/pids/puma.pid

start: setup start_puma

pumap: setupp start_puma

start_puma:
	puma -C config/puma.rb

# @see https://gist.github.com/tachesimazzoca/3891036
restart_puma:
	@[[ -s "$(PID)" ]] && kill -USR2 `cat $(PID)`

stop_puma:
	@[[ -s "$(PID)" ]] && kill -QUIT `cat $(PID)`

setup:
	rake db:drop db:create db:migrate db:seed

setupp:
	RAILS_ENV=production rake db:drop db:create db:migrate db:seed

test_prepare:
	rake db:test:prepare
	rake db:test:load

c:
	rails c

sidekiq:
	bundle exec sidekiq -e development -q default -L log/sidekiq.log -C config/sidekiq.yml -d

sidekiqp:
	bundle exec sidekiq -e production -q default -L log/sidekiq.log -C config/sidekiq.yml -d
