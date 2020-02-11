CREATE DATABASE IF NOT EXISTS shinobi_dev;

CREATE USER 'shinobi_dev_user'@'*' IDENTIFIED BY 'pass';
GRANT ALL PRIVILEGES ON shinobi_dev.* TO 'shinobi_dev_user'@'*';
FLUSH PRIVILEGES;

