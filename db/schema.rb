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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "accesses", :force => true do |t|
    t.string   "controller",      :limit => 50
    t.string   "action",          :limit => 50
    t.string   "item_id",         :limit => 50
    t.string   "method",          :limit => 6
    t.boolean  "is_xhr"
    t.string   "remote_ip"
    t.string   "http_user_agent", :limit => 1000
    t.text     "http_referer"
    t.text     "query_string"
    t.integer  "user_id"
    t.datetime "created_at",                      :null => false
    t.integer  "tag_id"
    t.float    "duration"
    t.string   "imei",            :limit => 100
  end

  add_index "accesses", ["controller", "action", "item_id"], :name => "Index_2"
  add_index "accesses", ["tag_id"], :name => "Index_3"

  create_table "app_locales", :force => true do |t|
    t.string  "code",         :limit => 5,                 :null => false
    t.string  "name",         :limit => 45
    t.integer "app_id",                                    :null => false
    t.integer "version_code",               :default => 0, :null => false
  end

  add_index "app_locales", ["app_id"], :name => "app_id"
  add_index "app_locales", ["code"], :name => "code"

  create_table "app_tags", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "app_id",     :null => false
    t.integer  "tag_id",     :null => false
    t.datetime "created_at", :null => false
  end

  add_index "app_tags", ["app_id"], :name => "app_id"
  add_index "app_tags", ["tag_id"], :name => "tag_id"
  add_index "app_tags", ["user_id", "app_id", "tag_id"], :name => "user_app_tag", :unique => true
  add_index "app_tags", ["user_id"], :name => "user_id"

  create_table "apps", :force => true do |t|
    t.string   "name",                    :limit => 100
    t.integer  "version_code",                            :default => -1,    :null => false
    t.string   "version_name",            :limit => 100
    t.string   "package",                 :limit => 200,                     :null => false
    t.string   "icon",                    :limit => 500
    t.string   "apk",                     :limit => 500
    t.string   "signature",               :limit => 50,                      :null => false
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.integer  "size",                                    :default => 0,     :null => false
    t.integer  "reviews_count",                           :default => 0,     :null => false
    t.integer  "likes_count",                             :default => 0,     :null => false
    t.integer  "dev_id"
    t.string   "description",             :limit => 500
    t.string   "contact",                 :limit => 200
    t.boolean  "enabled",                                 :default => true,  :null => false
    t.string   "dev_extemail",            :limit => 100
    t.datetime "dev_extemail_updated_at"
    t.datetime "dev_engaged_at"
    t.boolean  "on_cloud",                                :default => false, :null => false
    t.string   "review",                  :limit => 5000
    t.integer  "downloads_count"
  end

  add_index "apps", ["package", "signature"], :name => "uid", :unique => true

  create_table "apps0", :force => true do |t|
    t.string   "name",          :limit => 100
    t.integer  "version_code",                 :default => -1, :null => false
    t.string   "version_name",  :limit => 100
    t.string   "package",       :limit => 200,                 :null => false
    t.string   "icon",          :limit => 500
    t.string   "apk",           :limit => 500
    t.string   "signature",     :limit => 50,                  :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "size",                         :default => 0,  :null => false
    t.integer  "reviews_count",                :default => 0,  :null => false
  end

  add_index "apps0", ["package", "signature"], :name => "uid", :unique => true

  create_table "claims", :primary_key => "claim_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "app_id",     :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "claims", ["app_id"], :name => "app_id"
  add_index "claims", ["updated_at"], :name => "updated_at"
  add_index "claims", ["user_id"], :name => "user_id"

  create_table "comments", :force => true do |t|
    t.string   "content",               :limit => 140,                 :null => false
    t.integer  "user_id"
    t.datetime "created_at",                                           :null => false
    t.integer  "app_id"
    t.integer  "in_reply_to_id"
    t.string   "sns_status_id",         :limit => 45
    t.string   "sns_id",                :limit => 45
    t.string   "model",                 :limit => 200
    t.integer  "sdk"
    t.integer  "digs_count",                            :default => 0, :null => false
    t.string   "in_reply_to_user_json", :limit => 2000
    t.string   "image",                 :limit => 200
    t.integer  "image_size"
    t.text     "above_ids"
    t.text     "below_ids"
    t.string   "below_json",            :limit => 2000
    t.integer  "watches_count",                         :default => 0, :null => false
  end

  add_index "comments", ["app_id"], :name => "app_id"
  add_index "comments", ["created_at"], :name => "created_at"
  add_index "comments", ["user_id"], :name => "user_id"

  create_table "digs", :primary_key => "dig_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "comment_id", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "created_at"
  end

  add_index "digs", ["comment_id"], :name => "Index_3"
  add_index "digs", ["updated_at"], :name => "Index_4"
  add_index "digs", ["user_id", "comment_id"], :name => "unique", :unique => true
  add_index "digs", ["user_id"], :name => "Index_2"

  create_table "downloads", :force => true do |t|
    t.integer  "app_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.string   "source",     :limit => 45
    t.integer  "comment_id"
  end

  add_index "downloads", ["app_id"], :name => "app_id"
  add_index "downloads", ["created_at"], :name => "created_at"
  add_index "downloads", ["user_id"], :name => "user_id"

  create_table "exclude_emails", :primary_key => "in", :force => true do |t|
    t.string   "email",      :limit => 100, :null => false
    t.datetime "created_at",                :null => false
  end

  add_index "exclude_emails", ["email"], :name => "email"

  create_table "feeds", :force => true do |t|
    t.integer  "user_id",                    :null => false
    t.integer  "producer_id"
    t.string   "title",       :limit => 200
    t.string   "content",     :limit => 200
    t.datetime "created_at"
    t.string   "object_type", :limit => 45
    t.integer  "object_id"
  end

  add_index "feeds", ["created_at"], :name => "created_at"
  add_index "feeds", ["user_id"], :name => "user_id"

  create_table "flags", :primary_key => "flag_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "app_id",     :null => false
    t.datetime "updated_at", :null => false
    t.datetime "created_at"
  end

  add_index "flags", ["app_id"], :name => "Index_3"
  add_index "flags", ["updated_at"], :name => "Index_4"
  add_index "flags", ["user_id", "app_id"], :name => "unique", :unique => true
  add_index "flags", ["user_id"], :name => "Index_2"

  create_table "follows", :primary_key => "follow_id", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "following_id", :null => false
    t.datetime "updated_at",   :null => false
    t.datetime "created_at"
  end

  add_index "follows", ["following_id"], :name => "Index_3"
  add_index "follows", ["updated_at"], :name => "Index_4"
  add_index "follows", ["user_id", "following_id"], :name => "unique", :unique => true
  add_index "follows", ["user_id"], :name => "Index_2"

  create_table "installs", :force => true do |t|
    t.string   "imei",       :limit => 45
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "installs", ["created_at"], :name => "created_at"
  add_index "installs", ["imei"], :name => "imei", :unique => true
  add_index "installs", ["updated_at"], :name => "updated_at"
  add_index "installs", ["user_id"], :name => "user_id"

  create_table "invites", :force => true do |t|
    t.integer  "invitor_id"
    t.string   "request_id",  :limit => 100
    t.integer  "invite_code",                :null => false
    t.integer  "invitee_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.string   "invitee_eid", :limit => 45
  end

  add_index "invites", ["invite_code"], :name => "invte_code", :unique => true

  create_table "likes", :primary_key => "like_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "app_id",     :null => false
    t.datetime "updated_at", :null => false
    t.datetime "created_at"
  end

  add_index "likes", ["app_id"], :name => "Index_3"
  add_index "likes", ["updated_at"], :name => "Index_4"
  add_index "likes", ["user_id", "app_id"], :name => "unique", :unique => true
  add_index "likes", ["user_id"], :name => "Index_2"

  create_table "mentions", :primary_key => "mention_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "friend_id",  :null => false
    t.datetime "created_at"
  end

  add_index "mentions", ["user_id", "friend_id"], :name => "unique", :unique => true
  add_index "mentions", ["user_id"], :name => "Index_2"

  create_table "metions", :primary_key => "metion_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "friend_id",  :null => false
    t.datetime "created_at"
  end

  add_index "metions", ["user_id", "friend_id"], :name => "unique", :unique => true
  add_index "metions", ["user_id"], :name => "Index_2"

  create_table "notifications", :primary_key => "notification_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "comment_id", :null => false
    t.datetime "created_at"
  end

  add_index "notifications", ["created_at"], :name => "Index_4"
  add_index "notifications", ["user_id"], :name => "Index_2"

  create_table "recent_accesses", :force => true do |t|
    t.string   "controller",      :limit => 50
    t.string   "action",          :limit => 50
    t.integer  "item_id"
    t.string   "method",          :limit => 6
    t.boolean  "is_xhr"
    t.string   "remote_ip",       :limit => 15
    t.string   "http_user_agent", :limit => 1000
    t.text     "http_referer"
    t.text     "query_string"
    t.integer  "user_id"
    t.datetime "created_at",                      :null => false
    t.integer  "tag_id"
    t.float    "duration"
    t.string   "imei",            :limit => 100
  end

  add_index "recent_accesses", ["controller", "action", "item_id"], :name => "Index_2"
  add_index "recent_accesses", ["tag_id"], :name => "Index_3"

  create_table "reports", :force => true do |t|
    t.string   "category",      :limit => 45
    t.string   "name",          :limit => 500
    t.string   "sql",           :limit => 2000, :null => false
    t.datetime "created_at"
    t.string   "param_name",    :limit => 45
    t.string   "param_default", :limit => 500
    t.string   "lookups",       :limit => 500
  end

  create_table "settings", :force => true do |t|
    t.integer "user_id",                                           :null => false
    t.boolean "notice_follow",                   :default => true
    t.boolean "notice_update",                   :default => true
    t.boolean "notice_dm",                       :default => true
    t.boolean "notice_comment",                  :default => true
    t.string  "oauth_twitter",    :limit => 500
    t.string  "oauth_facebook",   :limit => 500
    t.string  "oauth_buzz",       :limit => 500
    t.string  "options_twitter",  :limit => 500
    t.string  "options_facebook", :limit => 500
    t.string  "options_buzz",     :limit => 500
    t.string  "oauth_sina",       :limit => 500
    t.string  "user_id_buzz",     :limit => 500
    t.string  "user_id_twitter",  :limit => 500
    t.string  "user_id_facebook", :limit => 500
    t.string  "user_id_sina",     :limit => 500
    t.string  "oauth_qq",         :limit => 500
    t.string  "user_id_qq",       :limit => 500
    t.string  "signup_sns",       :limit => 45
    t.string  "oauth_plus",       :limit => 500
    t.string  "user_id_plus",     :limit => 500
  end

  add_index "settings", ["user_id"], :name => "user_id"

  create_table "shares", :primary_key => "share_id", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.integer  "app_id",                      :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "version_name", :limit => 100
  end

  add_index "shares", ["app_id"], :name => "app_id"
  add_index "shares", ["updated_at"], :name => "updated_at"
  add_index "shares", ["user_id"], :name => "user_id"

  create_table "tags", :force => true do |t|
    t.string   "name",       :limit => 45, :null => false
    t.datetime "created_at",               :null => false
  end

  add_index "tags", ["name"], :name => "name_UNIQUE", :unique => true

  create_table "user_signs", :primary_key => "user_sign_id", :force => true do |t|
    t.integer  "user_id",                  :null => false
    t.datetime "updated_at",               :null => false
    t.string   "signature",  :limit => 50, :null => false
  end

  add_index "user_signs", ["signature"], :name => "signature"
  add_index "user_signs", ["updated_at"], :name => "updated_at"
  add_index "user_signs", ["user_id"], :name => "user_id"

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "remember_token_expires"
    t.string   "remember_token",         :limit => 200
    t.boolean  "enabled",                                :default => true
    t.boolean  "is_admin"
    t.integer  "followings_count"
    t.integer  "followers_count"
    t.integer  "shares_count"
    t.string   "name",                   :limit => 45
    t.string   "options",                :limit => 5000
    t.string   "lang",                   :limit => 45
    t.datetime "invite_at"
    t.datetime "updated_at"
    t.string   "imei",                   :limit => 200
    t.integer  "client_version"
    t.string   "country_code",           :limit => 45
    t.string   "username",               :limit => 45
    t.string   "email",                  :limit => 200
    t.string   "password",               :limit => 45
    t.string   "photo",                  :limit => 500
    t.string   "bio",                    :limit => 160
    t.string   "location",               :limit => 45
    t.string   "web",                    :limit => 100
    t.integer  "claims_count"
    t.integer  "reviews_count",                          :default => 0,     :null => false
    t.boolean  "activated",                              :default => false, :null => false
    t.integer  "likes_count",                            :default => 0,     :null => false
    t.integer  "digs_count",                             :default => 0,     :null => false
    t.string   "banner",                 :limit => 500
    t.integer  "watches_count",                          :default => 0,     :null => false
  end

  add_index "users", ["updated_at"], :name => "updated_at"

  create_table "watches", :primary_key => "watch_id", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "comment_id", :null => false
    t.datetime "created_at"
  end

  add_index "watches", ["comment_id"], :name => "Index_3"
  add_index "watches", ["created_at"], :name => "Index_4"
  add_index "watches", ["user_id", "comment_id"], :name => "unique", :unique => true
  add_index "watches", ["user_id"], :name => "Index_2"

end
