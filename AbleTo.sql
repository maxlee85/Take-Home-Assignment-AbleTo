--What was the temperature, date, and station with the highest recorded temperature in NY since 2010?
--standardSQL
WITH TEMP_DETAILS AS (
      SELECT a.year || '-' || a.mo || '-' || a.da as date
           , a.stn || '-' || a.wban as station
           , max(a.max) as temperature
        FROM `bigquery-public-data.noaa_gsod.gsod20*` a
  INNER JOIN `bigquery-public-data.noaa_gsod.stations` b
          ON a.stn = b.usaf
         AND a.wban = b.wban
         AND b.country = 'US'
         AND b.state = 'NY'
       WHERE a.max != 9999.9
         AND a._TABLE_SUFFIX BETWEEN '10'
         AND '20'
    GROUP BY 1,2
)

  SELECT *
    FROM temp_details
ORDER BY temperature DESC
   LIMIT 1
;

--On what day in 2016 did cumulative precipitation for Central Park (stn = 725053, wban = 94728) cross 30 total inches for the year?
--standardSQL
WITH PRCP_DETAILS AS (
      SELECT a.mo
           , a.da
           , a.prcp
           , SUM(a.prcp) OVER (ORDER BY a.mo, a.da) as cum_prcp
        FROM `bigquery-public-data.noaa_gsod.gsod2016` a
  INNER JOIN `bigquery-public-data.noaa_gsod.stations` b
          ON a.stn = b.usaf
         AND a.wban = b.wban
         AND a.stn = '725053'
         AND a.wban = '94728'
       WHERE a.prcp != 99.99
)

  SELECT *
    FROM prcp_details
   WHERE cum_prcp > 30
ORDER BY cum_prcp
   LIMIT 1
;

--What percent of NY stations active in 2016 (start before 1/1/2016 and end after 12/31/2016) had 3 consecutive days of snowfall in 2016?
--standardSQL
WITH NY_STATIONS AS (
SELECT usaf
     , wban
  FROM `bigquery-public-data.noaa_gsod.stations`
 WHERE state = 'NY'
   AND country = 'US'
   AND begin < '20160101'
   AND `end` > '20161231'
),

CUM_NY_STATIONS AS (
      SELECT distinct b.stn || '-' || b.wban
        FROM NY_STATIONS a
  INNER JOIN `bigquery-public-data.noaa_gsod.gsod2016` b
          ON a.usaf = b.stn
         AND a.wban = b.wban
         AND b.snow_ice_pellets = '1'
  INNER JOIN `bigquery-public-data.noaa_gsod.gsod2016` b2
          ON b.stn = b2.stn
         AND b.wban = b2.wban
         AND b2.snow_ice_pellets = '1'
         AND date_add(cast(b.year || '-' || b.mo || '-' || b.da as date), INTERVAL 1 DAY) = cast(b2.year || '-' || b2.mo || '-' || b2.da as date)
  INNER JOIN `bigquery-public-data.noaa_gsod.gsod2016` b3
          ON b.stn = b3.stn
         AND b.wban = b3.wban
         AND b3.snow_ice_pellets = '1'
         AND date_add(cast(b.year || '-' || b.mo || '-' || b.da as date), INTERVAL 2 DAY) = cast(b3.year || '-' || b3.mo || '-' || b3.da as date)
)

SELECT (select count(*) from cum_ny_stations)/(select count(*) from ny_stations)
;
