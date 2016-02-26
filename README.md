## README

Srs callback with srs 2.0 release and ffmpeg.

* ruby: 2.3.0
* rails: 5.0 beta3
* mysql: 5.6+
* ffmpeg: 2.1.1+(2.8.4)
* srs: 2.0release or 3.0develop
* sidekiq 4.0.2+
* redis: 2.8.4+
* [srs.conf](https://github.com/FlowerWrong/srs_callback/blob/master/config/srs.conf)
* [srs wiki](https://github.com/ossrs/srs/wiki)

```bash
bower install
bundle install

# for development
make
make sidekiq

# for production
make start_puma
```

## srs 2.0

```bash
git clone https://github.com/ossrs/srs.git
cd srs/trunk
./configure --disable-all --with-ssl --with-hls --with-nginx --with-ffmpeg --with-transcode --with-dvr --with-http-api --with-http-callback --with-http-server

make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## srs 3.0

```bash
./configure --disable-all --with-hls --with-hds --with-dvr --with-nginx --with-ssl --with-ffmpeg --with-transcode --with-ingest --with-stat --with-http-callback --with-http-server --with-stream-caster --with-kafka --with-http-api --with-librtmp --with-research --with-utest
make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## install ruby 2.3.0 from source code

```bash
wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz
tar -zxvf ruby-2.3.0.tar.gz
cd ruby-2.3.0/
./configure --prefix=/data/app/softwares/rubies
make
make install

sudo vim /etc/environment
# add `/data/app/softwares/rubies/bin` to path
source /etc/environment

ruby -v
gem -v

sudo ln -s /data/app/softwares/rubies/bin/ruby /usr/bin/ruby
sudo ln -s /data/app/softwares/rubies/bin/ /usr/bin/gem

gem sources -l
gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
gem sources -l

gem install bundler
```

## bugs

* `--with-http-server` must have, even if we are not using it.
