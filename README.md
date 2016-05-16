## README

Srs callback with srs 2.0 release and ffmpeg.

* ruby: 2.3.1
* rails: 5.0.0.rc1
* mysql: 5.6+
* ffmpeg: 2.1.1+(2.8.4)
* srs: 2.0release or 3.0develop
* sidekiq 4.0.2+
* redis: 2.8.4+
* [srs.conf](https://github.com/FlowerWrong/srs_callback/blob/master/config/srs.conf)
* [srs wiki](https://github.com/ossrs/srs/wiki)
* support ubuntu, centos and osx
* [google youtube 直播编码器设置、比特率和分辨率](https://support.google.com/youtube/answer/2853702?hl=zh-Hans)

```bash
bower install
bundle install

# for development
make
make sidekiq

# for production
make start_puma
```

## srs 2.0 on ubuntu

```bash
git clone https://github.com/ossrs/srs.git
cd srs/trunk
./configure --disable-all --with-ssl --with-hls --with-nginx --with-ffmpeg --with-transcode --with-dvr --with-http-api --with-http-callback --with-http-server

make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## srs 2.0 on osx

```bash
git clone https://github.com/ossrs/srs.git
cd srs/trunk
brew install pcre
brew install homebrew/dupes/zlib

./configure --osx --prefix=/Users/yang/dev/c/multimedia/srsbuild --disable-all --with-ssl --with-hls --with-nginx --with-ffmpeg --with-transcode --with-dvr --with-http-api --with-http-callback --with-http-server

make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## srs 3.0 on ubuntu

```bash
./configure --disable-all --with-hls --with-hds --with-dvr --with-nginx --with-ssl --with-ffmpeg --with-transcode --with-ingest --with-stat --with-http-callback --with-http-server --with-stream-caster --with-kafka --with-http-api --with-librtmp --with-research --with-utest
make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## install ruby 2.3.1 from source code

```bash
sudo apt-get install openssl libssl-dev
udo apt-get install mysql-server mysql-client libmysqlclient-dev

wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz
tar -zxvf ruby-2.3.1.tar.gz
cd ruby-2.3.1/
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
gem source -a https://gems.ruby-china.org --remove https://rubygems.org/
gem sources -l

gem install bundler
```

## build ffmpeg on mac

```zsh
brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-libass --with-libquvi --with-libvorbis --with-libvpx --with-opus --with-x265

git clone http://source.ffmpeg.org/git/ffmpeg.git ffmpeg
cd ffmpeg
git checkout origin/release/2.8
./configure --prefix=/Users/yang/dev/c/multimedia/ffmpeg-learning/ffmpegbuild --enable-gpl --enable-nonfree --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libxvid
make && make install
```

## bugs

* `--with-http-server` must have, even if I do not use it.

## hls cross

```nginx
location /{
  add_header 'Access-Control-Allow-Origin' 'http://domain.com';
  add_header 'Access-Control-Allow-Credentials' 'true';
  add_header 'Access-Control-Allow-Methods' 'GET';
}
```

[nginx cors](http://enable-cors.org/server_nginx.html)

## todo

- [x] avoid hls cache after live end, use a sidekiq task to del all *.ts file and *.m3u8
- [x] nginx 跨域 for hls only get method
- [ ] 直播服务地址的api
