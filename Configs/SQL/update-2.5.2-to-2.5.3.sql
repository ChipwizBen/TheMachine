ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `last_approved` `last_approved` DATETIME NULL;

ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `approved_by` `approved_by` VARCHAR(128) NULL;

ALTER TABLE `TheMachine`.`nagios_timedefinition` 
RENAME TO  `TheMachine`.`icinga2_timedefinition`;

ALTER TABLE `TheMachine`.`nagios_lnkHostToHostgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkHostToHostgroup`;













##########################################

