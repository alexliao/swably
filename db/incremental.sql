ALTER TABLE `nappstr`.`shares` 
ADD COLUMN `version_name` VARCHAR(100) NULL AFTER `updated_at`;

ALTER TABLE `nappstr`.`comments` 
ADD COLUMN `above_ids` TEXT NULL AFTER `image_size`,
ADD COLUMN `below_ids` TEXT NULL AFTER `above_ids`;

ALTER TABLE `nappstr`.`comments` 
ADD COLUMN `below_json` VARCHAR(2000) NULL AFTER `below_ids`;