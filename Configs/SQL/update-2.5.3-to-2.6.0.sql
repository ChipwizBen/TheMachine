ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `last_approved` `last_approved` DATETIME NULL;

ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `approved_by` `approved_by` VARCHAR(128) NULL;

ALTER TABLE `TheMachine`.`nagios_timedefinition` 
RENAME TO  `TheMachine`.`icinga2_timedefinition`;

ALTER TABLE `TheMachine`.`nagios_lnkHostToHostgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkHostToHostgroup`;

CREATE TABLE `TheMachine`.`config_proxmox` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `target_node` VARCHAR(128) NOT NULL,
  `target_port` INT(5) NOT NULL DEFAULT '8006',
  `username` VARCHAR(128) NOT NULL,
  `password` VARCHAR(128) NOT NULL,
  PRIMARY KEY (`id`));

