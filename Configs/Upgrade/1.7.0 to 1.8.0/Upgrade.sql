ALTER TABLE `Management`.`lock` 
ADD COLUMN `sudoers-distribution` INT(1) NOT NULL DEFAULT 0 AFTER `sudoers-build`,
ADD COLUMN `last-build-started` DATETIME NOT NULL AFTER `sudoers-distribution`,
ADD COLUMN `last-build-finished` DATETIME NOT NULL AFTER `last-build-started`,
ADD COLUMN `last-distribution-started` DATETIME NOT NULL AFTER `last-build-finished`,
ADD COLUMN `last-distribution-finished` DATETIME NOT NULL AFTER `last-distribution-started`,
DROP PRIMARY KEY,
ADD PRIMARY KEY (`sudoers-build`, `sudoers-distribution`, `last-build-started`, `last-build-finished`, `last-distribution-started`, `last-distribution-finished`);

