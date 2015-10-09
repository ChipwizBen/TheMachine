ALTER TABLE `Sudoers`.`user_groups` 
ADD COLUMN `system_group` INT(1) NOT NULL DEFAULT 0 AFTER `groupname`;

ALTER TABLE `Sudoers`.`rules` 
ADD COLUMN `all_hosts` INT(1) NOT NULL DEFAULT 0 AFTER `name`;

