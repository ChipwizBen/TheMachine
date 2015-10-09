ALTER TABLE `Management`.`distribution` 
ADD COLUMN `last_checkin` DATETIME NOT NULL AFTER `last_successful_transfer`;

