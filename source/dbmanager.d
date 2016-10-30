import std.variant;
import std.typecons;
import std.stdio;
import std.array;
import std.algorithm.iteration;

import mysql;

MysqlDB db;

shared static this()
{
    db = new MysqlDB(/*ip address, or localhost*/"127.0.0.1", /*user*/"ircbot",
                    /*password*/"somemagicalpassword", /*db-name*/"ProfanityBot");
}

immutable QUERY_USER =
"INSERT INTO Users (nickname, total_offenses, year_offenses, month_offenses, week_offenses, last_updated)
  VALUES (?, 1, 1, 1, 1, now())
ON DUPLICATE KEY UPDATE year_offenses=
(CASE WHEN YEAR(last_updated) = YEAR(NOW())
  THEN year_offenses + 1
  ELSE 1
END),
month_offenses=
(CASE WHEN MONTH(last_updated) = MONTH(NOW())
  THEN month_offenses + 1
  ELSE 1
END),
week_offenses=
(CASE WHEN WEEK(last_updated) = WEEK(NOW())
  THEN week_offenses + 1
  ELSE 1
END),
total_offenses = total_offenses + 1,
last_updated=NOW();";

immutable QUERY_PROFANITY =
"INSERT INTO Profanity (foul_word, total_uses)
  VALUES (?, 1)
ON DUPLICATE KEY UPDATE
  total_uses = total_uses + 1;";
  
immutable QUERY_FOUL_USAGE =
"INSERT INTO UserFoulUsage (count, word, user)
  VALUES (1, ?, ?)
ON DUPLICATE KEY UPDATE
  count = count + 1;";

bool storeProfanityUsage(string nickname, string word)
{
    writeln("Storing profanity usage...");
    auto con = db.lockConnection();
    scope(exit) con.close();
    
    bool success = true;
    ulong rowsChanged;
    
    //Insert user if they don't exist
    auto queryUserCmd = Command(con, QUERY_USER);
    queryUserCmd.prepare();
    queryUserCmd.bindParameter(nickname, 0);
    queryUserCmd.execPrepared(rowsChanged);
    if(rowsChanged == 0)
    {
        success = false;
    }
    
    //Insert bad word if it hasn't been used before
    auto queryWordCmd = Command(con, QUERY_PROFANITY);
    queryWordCmd.prepare();
    queryWordCmd.bindParameter(word, 0);
    queryWordCmd.execPrepared(rowsChanged);
    if(rowsChanged == 0)
    {
        success = false;
    }
    
    //Finally we do the exact same with the UserFoulUsage table...
    auto queryUsageCmd = Command(con, QUERY_FOUL_USAGE);
    queryUsageCmd.prepare();
    queryUsageCmd.bindParameter(word, 0);
    queryUsageCmd.bindParameter(nickname, 1);
    queryUsageCmd.execPrepared(rowsChanged);
    if(rowsChanged == 0)
    {
        success = false;
    }
    
    return success;
}


struct FoulUser
{
    string nickname;
    ulong total_offenses;
    ulong year_offenses;
    ulong month_offenses;
    ulong week_offenses;
}

immutable QUERY_FOULEST_MOUTH = 
"SELECT u.nickname, u.total_offenses, ufu.count, ufu.word
  FROM (Users u INNER JOIN UserFoulUsage ufu ON u.nickname = ufu.user)
  ORDER BY u.total_offenses DESC LIMIT 1;";

alias FoulMouthTuple = Nullable!(Tuple!(FoulUser, OffensiveWord));
FoulMouthTuple getFoulestMouth()
{
    auto con = db.lockConnection();
    scope(exit) con.close();
    //Return the user with the most foul word offenses,
    //as well as the number of foul words used,
    //and the most common foul word spoken by this person
    auto queryFoulestCmd = Command(con, QUERY_FOULEST_MOUTH);
    queryFoulestCmd.prepare();
    auto result = queryFoulestCmd.execPreparedResult();
    if(result.length >= 1)
    {
        FoulUser user;
        OffensiveWord word;
        auto entry = result.front();
        user.nickname = entry[0].get!(string);
        user.total_offenses = entry[1].get!(ulong);
        word.total_uses = entry[2].get!(ulong);
        word.foul_word = entry[3].get!(string);
        
        return FoulMouthTuple(tuple(user, word));
    }
    
    return FoulMouthTuple.init;
}

struct OffensiveWord
{
    string foul_word;
    ulong total_uses;
}

immutable QUERY_COMMON_OFFENSES = 
"SELECT foul_word, total_uses FROM Profanity
  ORDER BY total_uses DESC LIMIT 5;";

OffensiveWord[] getMostCommonOffenses()
{
    auto con = db.lockConnection();
    scope(exit) con.close();
    
    OffensiveWord toWord(Row r)
    {
        OffensiveWord word;
        r.toStruct(word);
        return word;
    }
    //Return the top 5 most common foul words,
    //allong with their total usages.
    auto queryCommonCmd = Command(con, QUERY_COMMON_OFFENSES);
    queryCommonCmd.prepare();
    auto result = queryCommonCmd.execPreparedResult();
    if(result.length >= 1)
    {
        return array(map!(r => toWord(r))(result));
    }
    
    return null;
}

immutable QUERY_MY_OFFENSES = 
"SELECT * FROM UserFoulUsage
  WHERE user = ?
  ORDER BY count DESC LIMIT 5;";

OffensiveWord[] getMyOffenses(string user)
{
    auto con = db.lockConnection();
    scope(exit) con.close();
    
    OffensiveWord toWord(Row r)
    {
        OffensiveWord word;
        word.total_uses = r[0].get!(ulong);
        word.foul_word = r[1].get!(string);
        return word;
    }
    //Return the top 5 most common foul words,
    //allong with their total usages.
    auto queryCmd = Command(con, QUERY_MY_OFFENSES);
    queryCmd.prepare();
    queryCmd.bindParameter(user, 0);
    auto result = queryCmd.execPreparedResult();
    if(result.length >= 1)
    {
        return array(map!(r => toWord(r))(result));
    }
    
    return null;
}

immutable QUERY_GET_USER = 
"SELECT * FROM Users
  WHERE nickname = ?;";

Nullable!FoulUser getUser(string user)
{
    auto con = db.lockConnection();
    scope(exit) con.close();
    
    auto queryFoulestCmd = Command(con, QUERY_GET_USER);
    queryFoulestCmd.prepare();
    queryFoulestCmd.bindParameter(user, 0);
    auto result = queryFoulestCmd.execPreparedResult();
    if(result.length >= 1)
    {
        auto entry = result.front();
        FoulUser fuser;
        entry.toStruct(fuser);
        return Nullable!FoulUser(fuser);
    }
    
    return Nullable!FoulUser.init;
}