CREATE TABLE `TheMachine`.`services` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `service` VARCHAR(255) NULL,
  `active` INT(1) NOT NULL DEFAULT 1,
  `expires` DATE NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` VARCHAR(128) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`service_dependency` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `service_id` INT(11) NOT NULL,
  `dependent_service_id` INT(11) NOT NULL,
  `dependent_host_id` INT(11) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`services_to_hosts_lnk` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `service_id` INT(11) NOT NULL,
  `host_id` INT(11) NOT NULL,
  PRIMARY KEY (`id`));

