-- Okuna database
CREATE DATABASE okuna;
CREATE USER okuna WITH PASSWORD 'okuna';
GRANT ALL PRIVILEGES ON DATABASE okuna TO okuna;
\connect okuna
GRANT USAGE, CREATE ON SCHEMA public TO okuna;
CREATE EXTENSION IF NOT EXISTS postgis;
\disconnect

-- Okuna test database
CREATE DATABASE okuna_test;
CREATE USER okuna_test WITH PASSWORD 'okuna-test';
GRANT ALL PRIVILEGES ON DATABASE okuna_test TO okuna_test;
\connect okuna_test
GRANT USAGE, CREATE ON SCHEMA public TO okuna_test;
CREATE EXTENSION IF NOT EXISTS postgis;
\disconnect

-- Moderation database
CREATE DATABASE moderation;
CREATE USER moderation WITH PASSWORD 'moderation';
GRANT ALL PRIVILEGES ON DATABASE moderation TO moderation;
\connect moderation
GRANT USAGE, CREATE ON SCHEMA public TO moderation;
\disconnect

-- Moderation federator
CREATE DATABASE hasura;
GRANT ALL PRIVILEGES ON DATABASE hasura TO moderation;

-- Chat database
CREATE DATABASE chat TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C';
CREATE USER chat WITH PASSWORD 'chat';
GRANT ALL PRIVILEGES ON DATABASE chat TO chat;
\connect chat
GRANT USAGE, CREATE ON SCHEMA public TO chat;
\disconnect

-- Rewards database
CREATE DATABASE rewards;
CREATE USER rewards WITH PASSWORD 'rewards';
GRANT ALL PRIVILEGES ON DATABASE rewards TO rewards;
\connect rewards
GRANT USAGE, CREATE ON SCHEMA public TO rewards;
\disconnect

-- Volunteering database
CREATE DATABASE volunteering;
CREATE USER volunteering WITH PASSWORD 'volunteering';
GRANT ALL PRIVILEGES ON DATABASE volunteering TO volunteering;
\connect volunteering
GRANT USAGE, CREATE ON SCHEMA public TO volunteering;
\disconnect