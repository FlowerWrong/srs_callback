## README

Srs callback with srs 2.0 release and ffmpeg.

* ruby: 2.3.0
* rails: 5.0 beta1
* mysql: 5+
* ffmpeg: 2.1+(2.8.4)
* srs: 2.0release

```bash
bower install
bundle install

# for development
make

# for production
make start_puma
```

## srs

```bash
git clone https://github.com/ossrs/srs.git
cd srs/trunk
./configure --disable-all --with-ssl --with-hls --with-nginx --with-ffmpeg --with-transcode --with-dvr --with-http-api --with-http-callback --with-http-server

make

sudo ./objs/nginx/sbin/nginx
./objs/srs -c conf/srs.conf
```

## bugs

* `--with-http-server` must have, even if we are not using it.

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
ruby -v
gem -v

sudo ln -s /data/app/softwares/rubies/bin/ruby /usr/bin/ruby
sudo ln -s /data/app/softwares/rubies/bin/ /usr/bin/gem

gem sources -l
gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
gem sources -l

gem install bundler
```

## srs.conf

```nginx
listen              1935;
max_connections     1000;
srs_log_tank        file;
srs_log_file        ./objs/srs.log;

srs_log_level       info;

#############################################################################################
# HTTP sections
#############################################################################################

stats {
    network         0;
    disk            sda sdb xvda xvdb;
}
http_api {
    enabled         on;
    listen          1985;
    crossdomain     on;
}

vhost __defaultVhost__ {
    security {
        enabled         off;
        # deny            publish     all;
        allow           publish     192.168.10.196;
        allow           publish     127.0.0.1;
        allow           play        all;
    }

    dvr {
        enabled         on;
        dvr_plan        session;
        dvr_path        ./objs/nginx/html/[app]/[stream].[timestamp].flv;
        dvr_duration    30;
        dvr_wait_keyframe       on;
        time_jitter             full;
    }

    transcode {
        enabled     on;
        ffmpeg      /home/yy/bin/ffmpeg;
        engine sd {
            enabled         on;
            vfilter {
                max_interleave_delta 0;
            }
            vcodec          libx264;
            vbitrate        700;
            vfps            30;
            vwidth          426;
            vheight         240;
            vthreads        12;
            vprofile        main;
            vpreset         medium;
            vparams {
            }
            acodec          libfdk_aac;
            abitrate        70;
            asample_rate    44100;
            achannels       2;
            aparams {
            }
            output          rtmp://127.0.0.1:[port]/[app]?vhost=[vhost]/[stream]_[engine];
        }
    }

    hls {
        enabled         on;
        hls_fragment    10;
        hls_td_ratio    1.5;
        hls_aof_ratio   2.0;
        hls_window      60;
        hls_on_error    continue;
        hls_storage     disk;
        hls_path        ./objs/nginx/html;
        hls_m3u8_file   [app]/[stream].m3u8;
        hls_ts_file     [app]/[stream]-[seq].ts;
        hls_ts_floor    off;
        hls_mount       [vhost]/[app]/[stream].m3u8;
        hls_acodec      aac;
        hls_vcodec      h264;
        hls_cleanup     on;
        hls_dispose     0;
        hls_nb_notify   64;
        hls_wait_keyframe       on;
    }

    http_hooks {
        enabled         on;
        on_connect      http://127.0.0.1:8085/api/v1/clients http://localhost:8085/api/v1/clients;
        on_close        http://127.0.0.1:8085/api/v1/clients http://localhost:8085/api/v1/clients;
        on_publish      http://127.0.0.1:8085/api/v1/streams http://localhost:8085/api/v1/streams;
        on_unpublish    http://127.0.0.1:8085/api/v1/streams http://localhost:8085/api/v1/streams;
        on_play         http://127.0.0.1:8085/api/v1/sessions http://localhost:8085/api/v1/sessions;
        on_stop         http://127.0.0.1:8085/api/v1/sessions http://localhost:8085/api/v1/sessions;
        on_dvr          http://127.0.0.1:8085/api/v1/dvrs http://localhost:8085/api/v1/dvrs;
        on_hls          http://127.0.0.1:8085/api/v1/hls http://localhost:8085/api/v1/hls;
        on_hls_notify   http://127.0.0.1:8085/api/v1/hls/[app]/[stream][ts_url];
    }
}
```
