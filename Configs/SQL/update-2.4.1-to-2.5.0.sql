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
  `dependent_service_id` INT(11),
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`lnk_services_to_hosts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `service_id` INT(11) NOT NULL,
  `host_id` INT(11) NOT NULL,
  `type` INT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`));


