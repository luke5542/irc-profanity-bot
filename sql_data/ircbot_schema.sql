CREATE DATABASE ProfanityBot;

USE ProfanityBot;

CREATE USER ircbot IDENTIFIED BY 'somemagicalpassword';
GRANT ALL PRIVILEGES ON  *.* to ircbot;

CREATE TABLE Users (
    nickname CHAR(50) NOT NULL UNIQUE PRIMARY KEY,
    total_offenses INT UNSIGNED,
    year_offenses INT UNSIGNED,
    month_offenses INT UNSIGNED,
    week_offenses INT UNSIGNED,
    last_updated DATETIME
);

CREATE TABLE Profanity (
    foul_word CHAR(50) NOT NULL UNIQUE PRIMARY KEY,
    total_uses INT UNSIGNED
);

CREATE TABLE UserFoulUsage (
    count INT UNSIGNED NOT NULL,
    word CHAR(50) NOT NULL,
    user CHAR(50) NOT NULL,
    CONSTRAINT FOREIGN KEY (word) REFERENCES Profanity (foul_word) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY (user) REFERENCES Users (nickname) ON DELETE CASCADE,
    CONSTRAINT ufu_id PRIMARY KEY (word, user)
);