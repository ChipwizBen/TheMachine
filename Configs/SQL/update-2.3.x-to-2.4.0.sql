ALTER TABLE `TheMachine`.`nagios_hosttemplate` 
RENAME TO  `TheMachine`.`icinga2_hosttemplate`;

ALTER TABLE `TheMachine`.`nagios_host` 
RENAME TO  `TheMachine`.`icinga2_host`;

ALTER TABLE `TheMachine`.`nagios_command` 
RENAME TO  `TheMachine`.`icinga2_command`;

ALTER TABLE `TheMachine`.`nagios_lnkHostToHost` 
RENAME TO  `TheMachine`.`icinga2_lnkHostToHost`;

ALTER TABLE `TheMachine`.`nagios_lnkHostToHosttemplate` 
RENAME TO  `TheMachine`.`icinga2_lnkHostToHosttemplate`;

ALTER TABLE `TheMachine`.`nagios_timeperiod` 
RENAME TO  `TheMachine`.`icinga2_timeperiod`;

ALTER TABLE `TheMachine`.`nagios_lnkHostToContactgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkHostToContactgroup`;

ALTER TABLE `TheMachine`.`nagios_contactgroup` 
RENAME TO  `TheMachine`.`icinga2_contactgroup`;

ALTER TABLE `TheMachine`.`nagios_lnkHosttemplateToHosttemplate` 
RENAME TO  `TheMachine`.`icinga2_lnkHosttemplateToHosttemplate`;

ALTER TABLE `TheMachine`.`nagios_lnkHosttemplateToContactgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkHosttemplateToContactgroup`;

ALTER TABLE `TheMachine`.`nagios_lnkHosttemplateToHost` 
RENAME TO  `TheMachine`.`icinga2_lnkHosttemplateToHost`;

ALTER TABLE `TheMachine`.`nagios_contact` 
RENAME TO  `TheMachine`.`icinga2_contact`;

ALTER TABLE `TheMachine`.`nagios_lnkContactToCommandService` 
RENAME TO  `TheMachine`.`icinga2_lnkContactToCommandService`;

ALTER TABLE `TheMachine`.`nagios_hostgroup` 
RENAME TO  `TheMachine`.`icinga2_hostgroup`;

ALTER TABLE `TheMachine`.`nagios_servicegroup` 
RENAME TO  `TheMachine`.`icinga2_servicegroup`;

ALTER TABLE `TheMachine`.`nagios_service` 
RENAME TO  `TheMachine`.`icinga2_service`;

ALTER TABLE `TheMachine`.`nagios_lnkServiceToServicegroup` 
RENAME TO  `TheMachine`.`icinga2_lnkServiceToServicegroup`;

ALTER TABLE `TheMachine`.`nagios_lnkServiceToServicetemplate` 
RENAME TO  `TheMachine`.`icinga2_lnkServiceToServicetemplate`;

ALTER TABLE `TheMachine`.`nagios_servicetemplate` 
RENAME TO  `TheMachine`.`icinga2_servicetemplate`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToServicegroup` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToServicegroup`;

ALTER TABLE `TheMachine`.`nagios_lnkContactToCommandHost` 
RENAME TO  `TheMachine`.`icinga2_lnkContactToCommandHost`;

ALTER TABLE `TheMachine`.`nagios_lnkServiceToContactgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkServiceToContactgroup`;

ALTER TABLE `TheMachine`.`nagios_lnkServiceToHost` 
RENAME TO  `TheMachine`.`icinga2_lnkServiceToHost`;

ALTER TABLE `TheMachine`.`nagios_lnkServiceToContact` 
RENAME TO  `TheMachine`.`icinga2_lnkServiceToContact`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToContactgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToContactgroup`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToContact` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToContact`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToHostgroup` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToHostgroup`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToHost` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToHost`;

ALTER TABLE `TheMachine`.`nagios_lnkServicetemplateToServicetemplate` 
RENAME TO  `TheMachine`.`icinga2_lnkServicetemplateToServicetemplate`;

