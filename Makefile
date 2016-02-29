.DEFAULT_GOAL = start

start: setup start_puma

pumap: setupp start_puma

start_puma:
	puma -C config/puma.rb

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
