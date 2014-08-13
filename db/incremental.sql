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

CREATE TABLE `nappstr`.`mentions` (
  `mention_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `friend_id` int(10) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`mention_id`),
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

CREATE TABLE `feeds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `producer_id` int(11) DEFAULT NULL,
  `title` varchar(200) DEFAULT NULL,
  `content` varchar(200) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `object_type` varchar(45) DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `created_at` (`created_at`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `installs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `imei` varchar(45) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `imei` (`imei`),
  KEY `user_id` (`user_id`),
  KEY `created_at` (`created_at`),
  KEY `updated_at` (`updated_at`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE `nappstr`.`downloads` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `app_id` INT NULL,
  `user_id` INT NULL,
  `created_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  INDEX `app_id` (`app_id` ASC),
  INDEX `user_id` (`user_id` ASC),
  INDEX `created_at` (`created_at` ASC))
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;
ALTER TABLE `nappstr`.`downloads` 
ADD COLUMN `source` VARCHAR(45) NULL AFTER `created_at`;

ALTER TABLE `nappstr`.`apps` 
ADD COLUMN `downloads_count` INT UNSIGNED NULL AFTER `review`;
ALTER TABLE `nappstr`.`downloads` 
CHANGE COLUMN `app_id` `app_id` INT(11) UNSIGNED NULL DEFAULT NULL ,
CHANGE COLUMN `user_id` `user_id` INT(11) UNSIGNED NULL DEFAULT NULL ,
ADD COLUMN `comment_id` INT UNSIGNED NULL AFTER `source`;

CREATE TABLE `nappstr`.`tags` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC))
ENGINE = MyISAM
DEFAULT CHARACTER SET = utf8;
CREATE TABLE `nappstr`.`app_tags` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `app_id` INT UNSIGNED NOT NULL,
  `tag_id` INT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `user_id` (`user_id` ASC),
  INDEX `app_id` (`app_id` ASC),
  INDEX `tag_id` (`tag_id` ASC),
  UNIQUE INDEX `user_app_tag` (`user_id` ASC, `app_id` ASC, `tag_id` ASC))
ENGINE = MyISAM
DEFAULT CHARACTER SET = utf8;

ALTER TABLE `nappstr`.`accesses` 
ADD INDEX `controller` (`controller` ASC),
ADD INDEX `action` (`action` ASC),
ADD INDEX `http_referer` (`http_referer`(255) ASC),
ADD INDEX `created_at` (`created_at` ASC);

