ALTER TABLE `TheMachine`.`ipv4_allocations` 
RENAME TO  `TheMachine`.`ipv4_assignments` ;

ALTER TABLE `TheMachine`.`lnk_hosts_to_ipv4_allocations` 
RENAME TO  `TheMachine`.`lnk_hosts_to_ipv4_assignments` ;

ALTER TABLE `TheMachine`.`ipv4_assignments` 
CHANGE COLUMN `ip_block` `ip_block` VARCHAR(18) NOT NULL ,
CHANGE COLUMN `parent_block` `parent_block` VARCHAR(18) NULL DEFAULT NULL ;

CREATE TABLE `lnk_hosts_to_ipv6_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` int(11) NOT NULL,
  `ip` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

CREATE TABLE `ipv6_blocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block_name` varchar(45) NOT NULL,
  `ip_block_description` varchar(128) DEFAULT NULL,
  `ip_block` varchar(43) NOT NULL,
  `gateway` varchar(39) DEFAULT NULL,
  `range_for_use` varchar(81) DEFAULT NULL,
  `range_for_use_subnet` varchar(39) DEFAULT NULL,
  `dns1` varchar(39) DEFAULT NULL,
  `dns2` varchar(39) DEFAULT NULL,
  `ntp1` varchar(39) DEFAULT NULL,
  `ntp2` varchar(39) DEFAULT NULL,
  `percent_used` varchar(5) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block_name`,`ip_block`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `ip_block_name_UNIQUE` (`ip_block_name`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

CREATE TABLE `ipv6_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block` varchar(43) NOT NULL,
  `parent_block` varchar(43) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;

CREATE TABLE `TheMachine`.`job_queue` (
  `job_id` INT NOT NULL,
  `override` INT(1) NOT NULL DEFAULT 0,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`),
  UNIQUE INDEX `job_id_UNIQUE` (`job_id` ASC));



