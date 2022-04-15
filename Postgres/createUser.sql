CREATE USER medinfo WITH PASSWORD 'tech1234';

GRANT USAGE ON SCHEMA wss TO medinfo;
 
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA wss TO medinfo;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA wss TO medinfo;