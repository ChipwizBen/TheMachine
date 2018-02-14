ALTER TABLE `TheMachine`.`config_ldap` 
ADD COLUMN `LDAP_User_Name_Suffix` VARCHAR(255) NULL DEFAULT NULL AFTER `LDAP_User_Name_Prefix`;

