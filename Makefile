.DEFAULT_GOAL = start

start:
	rake db:drop db:create db:migrate db:seed
	rails s -b 0.0.0.0 -p 8085

start_puma:
	RAILS_ENV=production rake db:drop db:create db:migrate db:seed
	puma -C config/puma.rb

setup:
	rake db:drop db:create db:migrate db:seed

test_prepare:
	rake db:test:prepare
	rake db:test:load

setupp:
	RAILS_ENV=production rake db:drop db:create db:migrate db:seed

startp:
	RAILS_ENV=production rake assets:precompile
	RAILS_ENV=production rails s -b 0.0.0.0

c:
	rails c

sidekiq:
	bundle exec sidekiq -e production -q default -L log/sidekiq.log -C config/sidekiq.yml -d
