require "spec"
require "tourmaline"
require "../src/private-parlor-xt/**"
require "./database/*"
require "./mocks/*"

HISTORY_LIFESPAN = Time::Span.zero

def create_sqlite_database : PrivateParlorXT::SQLiteDatabase
  connection = DB.open("sqlite3://%3Amemory%3A")

  connection.exec("CREATE TABLE IF NOT EXISTS system_config (
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (name)
  )")

  connection.exec("CREATE TABLE IF NOT EXISTS users (
    id BIGINT NOT NULL,
    username TEXT,
    realname TEXT NOT NULL,
    rank INTEGER NOT NULL,
    joined TIMESTAMP NOT NULL,
    left TIMESTAMP,
    lastActive TIMESTAMP NOT NULL,
    cooldownUntil TIMESTAMP,
    blacklistReason TEXT,
    warnings INTEGER NOT NULL,
    warnExpiry TIMESTAMP,
    karma INTEGER NOT NULL,
    hideKarma TINYINT NOT NULL,
    debugEnabled TINYINT NOT NULL,
    tripcode TEXT,
    PRIMARY KEY(id)
  )")

  # Add users
  connection.exec("INSERT INTO users VALUES (20000,'examp','example',1000,'2023-01-02 06:00:00.000',NULL,'2023-07-02 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")
  connection.exec("INSERT INTO users VALUES (60200,'voorb','voorbeeld',0,'2023-01-02 06:00:00.000',NULL,'2023-01-02 06:00:00.000',NULL,NULL,1,'2023-03-02 12:00:00.000',-10,0,0,NULL);")
  connection.exec("INSERT INTO users VALUES (80300,NULL,'beispiel',10,'2023-01-02 06:00:00.000',NULL,'2023-03-02 12:00:00.000',NULL,NULL,2,'2023-04-02 12:00:00.000',-20,0,1,NULL);")
  connection.exec("INSERT INTO users VALUES (40000,NULL,'esimerkki',0,'2023-01-02 06:00:00.000','2023-02-04 06:00:00.000','2023-02-04 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")
  connection.exec("INSERT INTO users VALUES (70000,NULL,'BLACKLISTED',-10,'2023-01-02 06:00:00.000','2023-04-02 10:00:00.000','2023-01-02 06:00:00.000',NULL,NULL,0,NULL,0,0,0,NULL);")

  PrivateParlorXT::SQLiteDatabase.new(connection)
end

def create_sqlite_history : PrivateParlorXT::SQLiteHistory
  connection = DB.open("sqlite3://%3Amemory%3A")
  connection.exec("PRAGMA foreign_keys = ON")

  connection.exec("CREATE TABLE IF NOT EXISTS message_groups (
    messageGroupID BIGINT NOT NULL,
    senderID BIGINT NOT NULL,
    sentTime TIMESTAMP NOT NULL,
    warned TINYINT NOT NULL,
    PRIMARY KEY (messageGroupID)
  )")

  connection.exec("CREATE TABLE IF NOT EXISTS receivers (
    receiverMSID BIGINT NOT NULL,
    receiverID BIGINT NOT NULL,
    messageGroupID BIGINT NOT NULL,
    PRIMARY KEY (receiverMSID),
    FOREIGN KEY (messageGroupID) REFERENCES message_groups(messageGroupID)
    ON DELETE CASCADE
  )")

  connection.exec("CREATE TABLE IF NOT EXISTS karma (
    messageGroupID BIGINT NOT NULL,
    userID BIGINT NOT NULL,
    PRIMARY KEY (messageGroupID),
    FOREIGN KEY (messageGroupID) REFERENCES receivers(receiverMSID)
    ON DELETE CASCADE
  )")

    # Add message groups
    connection.exec("INSERT INTO message_groups VALUES (1,80300,'2023-01-02 06:00:00.000',0)")
    connection.exec("INSERT INTO message_groups VALUES (4,20000,'2023-01-02 06:00:00.000',0)")
    connection.exec("INSERT INTO message_groups VALUES (8,60200,'2023-01-02 06:00:00.000',1)")
  
    # Add receivers
    connection.exec("INSERT INTO receivers VALUES (2,60200,1)")
    connection.exec("INSERT INTO receivers VALUES (3,20000,1)")
  
    connection.exec("INSERT INTO receivers VALUES (5,20000,4)")
    connection.exec("INSERT INTO receivers VALUES (6,80300,4)")
    connection.exec("INSERT INTO receivers VALUES (7,60200,4)")
  
    connection.exec("INSERT INTO receivers VALUES (9,20000,8)")
    connection.exec("INSERT INTO receivers VALUES (10,80300,8)")
  
    # Add karma
    connection.exec("INSERT INTO karma VALUES (2,60200)")

    PrivateParlorXT::SQLiteHistory.new(HISTORY_LIFESPAN, connection)
end
