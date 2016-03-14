# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160112050142) do

  create_table "live_clients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "client_id"
    t.string   "ip"
    t.string   "vhost"
    t.string   "app"
    t.string   "stream"
    t.string   "tc_url"
    t.integer  "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "client_id"
    t.string   "ip"
    t.string   "vhost"
    t.string   "app"
    t.string   "stream"
    t.string   "page_url"
    t.integer  "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transcodes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "live_client_id"
    t.string   "input_rtmp"
    t.string   "output_rtmp"
    t.string   "ip"
    t.string   "vhost"
    t.string   "app"
    t.string   "stream"
    t.integer  "status"
    t.integer  "pid"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

end
