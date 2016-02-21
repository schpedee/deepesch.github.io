-- Calculate the total number of edits, contributing users,  and net size change per topic, per hour

A = LOAD '/user/ubuntu/enwikipedia_logs' USING PigStorage('\t') AS (ts:datetime, topic:chararray, url:chararray, user:chararray, editsize:int, flags:chararray, comment:chararray);

--- Deduplicate source log data; use parallelism to mitigate chance of reducer failure
unique = DISTINCT A PARALLEL 2;

-- Input data is marked to the second, truncate date/time values to hour of day
temp = FOREACH unique GENERATE CONCAT((chararray)ToString(ts, 'yyyy-MM-dd\'T\'HH'), ':00:00Z') AS ts, topic, user, editsize;

B = FOREACH temp GENERATE FLATTEN($0) AS eventtime, topic, user, editsize;

C = group B by (eventtime, topic);

-- Bin each time interval (day), for each topic, with number of events, distinct users, and net editsize
D = FOREACH C {
    unique_users = DISTINCT B.user;
    net_editsize = SUM(B.editsize);
    GENERATE FLATTEN(group), COUNT(B), COUNT(unique_users) as user_count, net_editsize;
};

-- Sort output by date, then topic
sorted = ORDER D by $0, $1 ASC;

STORE sorted INTO '$output_path/$output_folder';
