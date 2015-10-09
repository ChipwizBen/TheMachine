CREATE USER 'Management'@'localhost' IDENTIFIED BY '<Password>';
GRANT SELECT,INSERT ON Management.access_log TO 'Management'@'localhost';
GRANT SELECT,INSERT ON Management.audit_log TO 'Management'@'localhost';
GRANT SELECT,INSERT,UPDATE,DELETE ON Management.credentials TO 'Management'@'localhost';
GRANT SELECT,INSERT,UPDATE,DELETE ON Management.distribution TO 'Management'@'localhost';
GRANT SELECT,UPDATE ON Management.lock TO 'Management'@'localhost';

CREATE USER 'Sudoers'@'localhost' IDENTIFIED BY '<Password>';
GRANT SELECT,INSERT,UPDATE,DELETE ON Sudoers.* TO 'Sudoers'@'localhost';

FLUSH PRIVILEGES;
