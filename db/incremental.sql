ALTER TABLE `nappstr`.`shares` 
ADD COLUMN `version_name` VARCHAR(100) NULL AFTER `updated_at`;

ALTER TABLE `nappstr`.`comments` 
ADD COLUMN `above_ids` TEXT NULL AFTER `image_size`,
ADD COLUMN `below_ids` TEXT NULL AFTER `above_ids`;

ALTER TABLE `nappstr`.`comments` 
ADD COLUMN `below_json` VARCHAR(2000) NULL AFTER `below_ids`;

CREATE TABLE `nappstr`.`watches` (
  `watch_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `comment_id` int(10) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`watch_id`),
  UNIQUE KEY `unique` (`user_id`,`comment_id`),
  KEY `Index_2` (`user_id`),
  KEY `Index_3` (`comment_id`),
  KEY `Index_4` (`created_at`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
ALTER TABLE `nappstr`.`users` 
ADD COLUMN `watches_count` INT(10) UNSIGNED NOT NULL DEFAULT 0 AFTER `banner`;
ALTER TABLE `nappstr`.`comments` 
ADD COLUMN `watches_count` INT(10) UNSIGNED NOT NULL DEFAULT 0 AFTER `below_json`;

ALTER TABLE `nappstr`.`settings` 
DROP COLUMN `user_id_sohu`,
DROP COLUMN `oauth_sohu`,
DROP COLUMN `user_id_163`,
DROP COLUMN `oauth_163`,
DROP COLUMN `user_id_douban`,
DROP COLUMN `user_id_renren`,
DROP COLUMN `oauth_douban`,
DROP COLUMN `oauth_renren`,
DROP INDEX `user_id_163` ,
DROP INDEX `oauth_163` ,
DROP INDEX `user_id_sohu` ,
DROP INDEX `oauth_sohu` ,
DROP INDEX `user_id_douban` ,
DROP INDEX `user_id_renren` ,
DROP INDEX `oauth_google` ,
DROP INDEX `oauth_douban` ,
DROP INDEX `oauth_renren` ;
ALTER TABLE `nappstr`.`settings` 
DROP INDEX `user_id_qq` ,
DROP INDEX `oauth_qq` ,
DROP INDEX `user_id_sina` ,
DROP INDEX `user_id_facebook` ,
DROP INDEX `user_id_twitter` ,
DROP INDEX `user_id_buzz` ,
DROP INDEX `oauth_sina` ,
DROP INDEX `oauth_facebook` ,
DROP INDEX `oauth_twitter` ;

CREATE TABLE `nappstr`.`metions` (
  `metion_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `friend_id` int(10) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`metion_id`),
  UNIQUE KEY `unique` (`user_id`,`friend_id`),
  KEY `Index_2` (`user_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `nappstr`.`notifications` (
  `notification_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `comment_id` int(10) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`notification_id`),
  KEY `Index_2` (`user_id`),
  KEY `Index_4` (`created_at`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

