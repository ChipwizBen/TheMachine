CREATE TABLE `Management`.`lock` (
  `sudoers-build` INT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sudoers-build`));
INSERT INTO `Management`.`lock` (`sudoers-build`) VALUES ('0');

GRANT SELECT,UPDATE ON Management.lock TO 'Management'@'localhost';

ALTER TABLE `Management`.`distribution` 
ADD COLUMN `sftp_port` INT(5) NOT NULL DEFAULT 22 AFTER `host_id`;

CREATE TABLE `Sudoers`.`notes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `type_id` INT(2) NOT NULL DEFAULT '00',
  `item_id` INT(11) NOT NULL,
  `note` TEXT NOT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` VARCHAR(128) NOT NULL,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  PRIMARY KEY (`id`));

