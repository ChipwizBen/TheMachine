ALTER TABLE `TheMachine`.`command_groups` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`commands` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`host_groups` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`hosts` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`user_groups` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`users` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`zone_records` 
CHANGE COLUMN `expires` `expires` DATE NULL ;

ALTER TABLE `TheMachine`.`credentials` 
CHANGE COLUMN `last_login` `last_login` DATETIME NULL ,
CHANGE COLUMN `last_active` `last_active` DATETIME NULL ;

ALTER TABLE `TheMachine`.`distribution` 
CHANGE COLUMN `last_updated` `last_updated` DATETIME NULL ,
CHANGE COLUMN `last_successful_transfer` `last_successful_transfer` DATETIME NULL ,
CHANGE COLUMN `last_checkin` `last_checkin` DATETIME NULL ;

