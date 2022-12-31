-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;
DROP VIEW IF EXISTS CAcollege;
DROP VIEW IF EXISTS slg;
DROP VIEW IF EXISTS lslg;
DROP VIEW IF EXISTS lslg_p;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear 
  FROM people 
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst ASC, namelast ASC 
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC 
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear ASC 
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, people.playerid, yearid
  FROM people INNER JOIN halloffame
  ON halloffame.playerID = people.playerID
  WHERE halloffame.inducted = 'Y'
  ORDER BY yearid DESC, people.playerid ASC
;

-- Question 2ii
DROP VIEW IF EXISTS CAcollage;
CREATE VIEW CAcollage(playerid, schoolid)
AS
  SELECT c.playerid, c.schoolid
  FROM collegeplaying c INNER JOIN schools s
  ON s.schoolid = c.schoolid
  WHERE s.schoolState = 'CA';

CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, q.playerid, schoolid, yearid
  FROM q2i q INNER JOIN CAcollage c
  ON q.playerid = c.playerid
  ORDER BY yearid DESC, schoolid, q.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT q2i.playerid, namefirst, namelast, cp.schoolid
  FROM q2i LEFT JOIN collegeplaying cp
  ON cp.playerid = q2i.playerid
  ORDER BY q2i.playerid DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW slg 
AS 
  SELECT playerid, yearid, (H + H2B + 2*H3B + 3*HR + 0.0)/(AB + 0.0) AS slg
  FROM batting
  WHERE AB > 50
;
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, s.yearid, slg
  FROM slg s LEFT JOIN people p
  ON s.playerid = p.playerid
  ORDER BY slg DESC, yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW lslg(playerid, lslg)
AS 
  SELECT playerid, (SUM(H) + SUM(H2B) + 2 * SUM(H3B) + 3 * SUM(HR) + 0.0)/(SUM(AB) + 0.0)
  FROM batting
  GROUP BY playerid
  HAVING SUM(AB) > 50
;

CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
SELECT p.playerid, namefirst, namelast, lslg
  FROM lslg s LEFT JOIN people p
  ON s.playerid = p.playerid
  ORDER BY lslg DESC, p.playerid ASC
  LIMIT 10
;


-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast, lslg
  FROM lslg s LEFT JOIN people p
  ON s.playerid = p.playerid
  WHERE lslg > (SELECT lslg FROM lslg WHERE playerid = 'mayswi01')
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
DROP TABLE IF EXISTS binids;
CREATE TABLE binids(binid);
INSERT INTO binids VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH params AS (SELECT 10 AS bucket_count),
       salaries_2016 AS (SELECT salary FROM salaries 
	WHERE yearid = '2016'),
       overall AS (SELECT MAX(salary) AS max_salary, MIN(salary) AS min_salary
	FROM salaries_2016),
       buckets AS (SELECT binid, 
	(min_salary + (max_salary - min_salary)/bucket_count*binid) AS low,
	(min_salary + (max_salary - min_salary)/bucket_count*(binid + 1)) AS high,
	max_salary
	FROM params, overall, binids)
  SELECT binid, low, high, COUNT(*)
  FROM buckets LEFT JOIN salaries_2016
  ON (salary >= low AND salary < high) OR (binid = 9 AND salary = max_salary)
  GROUP BY binid, low, high
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH salaries_year AS (SELECT yearid, MIN(salary) AS mins, MAX(salary) AS maxs, AVG(salary) AS avgs
	FROM salaries
	GROUP BY yearid
)
  SELECT s1.yearid, s1.mins - s2.mins, s1.maxs - s2.maxs, s1.avgs -s2.avgs
  FROM salaries_year s1 INNER JOIN salaries_year s2
  ON s1.yearid - 1 = s2.yearid;
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH max_salaries_2000 AS (SELECT MAX(salary) AS maxs
	FROM salaries
	WHERE yearid = '2000'
),
  max_salaries_2001 AS (SELECt MAX(salary) AS maxs
        FROM salaries
	WHERE yearid = '2001'
),
  max_salary AS (
  SELECT playerid, s.salary, yearid
  FROM salaries s, max_salaries_2000 s2000, max_salaries_2001 s2001
  WHERE (yearid = 2000 AND salary = s2000.maxs) 
  OR (yearid = 2001 AND salary = s2001.maxs))
  SELECT s.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM max_salary s LEFT JOIN people p
  ON s.playerid = p.playerid
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT t.teamid, MAX(salary) - MIN(salary)
  FROM salaries s INNER JOIN allstarfull t
  ON s.playerid = t.playerID AND s.yearid = t.yearID
  WHERE s.yearid = 2016
  GROUP BY t.teamid;
;
