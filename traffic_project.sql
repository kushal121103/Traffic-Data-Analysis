USE [traffic accident];
GO
SELECT  * FROM dbo.accident_prediction_india


--TOTAL NO. OF ACCIDNENT :

SELECT State_Name,Year, COUNT(Number_of_Vehicles_Involved) AS accident FROM dbo.accident_prediction_india
GROUP BY State_Name,Year
ORDER BY State_Name ASC ,Year ASC;


--TOP 10 state with more accident :

WITH CTE AS(
SELECT State_Name,COUNT(Accident_Severity) AS accident_count,year 
FROM dbo.accident_prediction_india
GROUP BY State_Name,year)
SELECT TOP 10 State_Name,accident_count ,year
FROM CTE
ORDER BY accident_count DESC,year DESC;


--high-accident zones (hotspots)
SELECT Accident_Location_Details,COUNT(Accident_Severity) AS accident_count 
FROM dbo.accident_prediction_india
GROUP BY Accident_Location_Details
ORDER BY accident_count  DESC;


--Accidents by time slot (morning/evening/night)
--Weekday vs weekend comparison
SELECT COUNT(Accident_Severity) AS accident_count, Day_of_Week,
                 CASE WHEN Day_of_Week IN('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY')
                           THEN 'WEEKDAYS'
                      WHEN Day_of_Week IN('SATURDAY','SUNDAY')
                           THEN 'WEEKEND'
                 END AS WEEK_INFO,
                 CASE WHEN Time_of_Day BETWEEN'05:00:00' AND'16:00:00' THEN 'MORNING'
                      WHEN Time_of_Day BETWEEN '16:00:00' AND'20:00:00' THEN 'EVENING'
                      ELSE 'NIGHT'
                 END AS TIME_SLOT
FROM dbo.accident_prediction_india
GROUP BY Day_of_Week,
    CASE 
        WHEN Day_of_Week IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY') THEN 'WEEKDAYS'
        WHEN Day_of_Week IN ('SATURDAY', 'SUNDAY') THEN 'WEEKEND'
    END,
    CASE 
        WHEN Time_of_Day BETWEEN '05:00:00' AND '16:00:00' THEN 'MORNING'
        WHEN Time_of_Day BETWEEN '16:00:00' AND '20:00:00' THEN 'EVENING'
        ELSE 'NIGHT'
    END
ORDER BY WEEK_INFO ASC ;


--Accidents during poor weather
WITH CTE AS(
SELECT COUNT(Accident_Severity) AS accident_count,Weather_Conditions,Road_Condition,Lighting_Conditions
FROM dbo.accident_prediction_india
GROUP BY Weather_Conditions,Road_Condition,Lighting_Conditions)
SELECT top 1 accident_count AS most_accident, Weather_Conditions, Road_Condition, Lighting_Conditions
FROM CTE
WHERE  Road_Condition='DRY'
ORDER BY Weather_Conditions,Road_Condition,Lighting_Conditions


--How many were fatal?
--Average number of people injured/killed per accident
SELECT SUM(Number_of_Fatalities) AS total_fatal,AVG(Number_of_Casualties) AS avg_casualties
FROM dbo.accident_prediction_india


--OBJ 1) What is the total number of casualties reported in the dataset?
SELECT SUM(Number_of_Casualties) AS Total_number_of_casualties
FROM dbo.accident_prediction_india;

--OBJ 2)Which state records the highest number of fatalities?
SELECT top 1 state_name,SUM(Number_of_Casualties) AS Casualties_per_state 
FROM  dbo.accident_prediction_india
GROUP BY state_name;

--OBJ 3)Which day of the week has the highest frequency of accidents?
SELECT TOP 1 Day_of_Week,COUNT(Accident_Severity) AS accident_occur
FROM dbo.accident_prediction_india
GROUP BY Day_of_Week
;
--OBJ 4)What is the distribution of accidents by severity (fatal, serious, slight)?
SELECT Accident_Severity,COUNT(Accident_Severity) AS accident_occur
FROM dbo.accident_prediction_india
GROUP BY Accident_Severity;

--OBJ 5)Which weather conditions are most associated with high casualty counts?
SELECT TOP 1 weather_conditions ,COUNT(Number_of_Casualties) AS no_of_casuality
FROM dbo.accident_prediction_india
GROUP BY weather_conditions ;

--OBJ 6) Which road conditions contribute to the highest number of fatalities?
SELECT TOP 1 Road_Condition,COUNT(Number_of_Fatalities) AS no_of_fatalities
FROM dbo.accident_prediction_india
GROUP BY Road_Condition;

--OBJ 7)Which combination of Weather_Condition, Road_Condition, and Lighting_Condition 
--leads to the highest fatality rate 
SELECT TOP 1 (SUM(Number_of_Fatalities)/COUNT(*)) AS fatality_rate,Weather_Conditions,Road_Condition,Lighting_Conditions
FROM dbo.accident_prediction_india
GROUP BY Weather_Conditions,Road_Condition,Lighting_Conditions;

--OBJ 8)What is the median number of casualties per accident across all states?
WITH ordered AS (
    SELECT 
        State_Name,
        Number_of_Casualties,
        ROW_NUMBER() OVER (PARTITION BY State_Name ORDER BY Number_of_Casualties) AS rn,
        COUNT(*) OVER (PARTITION BY State_Name) AS total_count
    FROM dbo.accident_prediction_india
)
SELECT 
    State_Name,
    ROUND(AVG(Number_of_Casualties * 1.0), 2) AS Median_Casualties
FROM ordered
WHERE 
    rn = total_count / 2 
    OR rn = (total_count + 1) / 2 
    OR rn = (total_count / 2) + 1
GROUP BY State_Name;
                      

--OBJ 9) Which states show opposite patterns of accident severity on weekdays vs weekends?
WITH CTE AS (
    SELECT 
        State_Name,
        CASE 
            WHEN Day_of_Week IN ('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY') THEN 'WEEKDAYS'
            WHEN Day_of_Week IN ('SATURDAY','SUNDAY') THEN 'WEEKEND'
        END AS WEEK_INFO,
        SUM(CASE WHEN Accident_Severity = 'FATAL' THEN 1 ELSE 0 END) AS fatal_count,
        SUM(CASE WHEN Accident_Severity = 'MINOR' THEN 1 ELSE 0 END) AS minor_count
    FROM dbo.accident_prediction_india
    GROUP BY 
        State_Name,
        CASE 
            WHEN Day_of_Week IN ('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY') THEN 'WEEKDAYS'
            WHEN Day_of_Week IN ('SATURDAY','SUNDAY') THEN 'WEEKEND'
        END
),
final AS (
    SELECT 
        State_Name,
        MAX(CASE WHEN WEEK_INFO = 'WEEKDAYS' THEN fatal_count END) AS fatal_weekdays,
        MAX(CASE WHEN WEEK_INFO = 'WEEKEND' THEN fatal_count END) AS fatal_weekend,
        MAX(CASE WHEN WEEK_INFO = 'WEEKDAYS' THEN minor_count END) AS minor_weekdays,
        MAX(CASE WHEN WEEK_INFO = 'WEEKEND' THEN minor_count END) AS minor_weekend
    FROM CTE
    GROUP BY State_Name
)
SELECT 
    State_Name,
    fatal_weekdays,
    fatal_weekend,
    minor_weekdays,
    minor_weekend,
    CASE 
        WHEN fatal_weekdays > fatal_weekend AND minor_weekdays < minor_weekend THEN 'Opposite Pattern'
        WHEN fatal_weekdays < fatal_weekend AND minor_weekdays > minor_weekend THEN 'Opposite Pattern'
        ELSE 'Not Opposite'
    END AS pattern_status
FROM final
WHERE 
    fatal_weekdays IS NOT NULL AND fatal_weekend IS NOT NULL 
    AND minor_weekdays IS NOT NULL AND minor_weekend IS NOT NULL;

--OBJ 10)What percentage of fatal accidents occur during nighttime across different weather conditions?
SELECT Weather_Conditions,COUNT(CASE WHEN Accident_Severity='FATAL' THEN 1 ELSE 0 END )*100.0/COUNT(*) AS fatal_accident_Percentage,
       'NIGHT' as time_slot
FROM  dbo.accident_prediction_india
WHERE CAST(Time_of_Day AS TIME )<'05:00:00' OR CAST(Time_of_Day AS TIME )>'20:00:00'
GROUP BY Weather_Conditions

--OBJ 11)Compare the ratio of minor to serious accidents across states.
SELECT State_Name ,
       ROUND(SUM(CASE WHEN Accident_Severity='minor' THEN 1 ELSE 0 END )/SUM(CASE WHEN Accident_Severity='serious' THEN 1 ELSE 0 END )*1.0,2) AS minor_to_serious_accident_ratio
FROM dbo.accident_prediction_india
GROUP BY State_Name;

--OBJ 12)Which state has the highest number of recurring accident hotspots (same location repeated)?
SELECT TOP 1 State_Name,Accident_Location_Details,COUNT(Accident_Severity) AS accident_count 
FROM dbo.accident_prediction_india
GROUP BY Accident_Location_Details,State_Name
ORDER BY accident_count  DESC

--OBJ 13) Which states have the lowest fatality rate during peak traffic hours (e.g., 6–10 AM and 5–9 PM)?
SELECT TOP 1 State_Name,SUM(CASE WHEN Accident_Severity='FATAL' THEN 1 ELSE 0 END)/COUNT(*) AS fatal_count
FROM dbo.accident_prediction_india
WHERE (CAST(Time_of_Day AS TIME ) BETWEEN '06:00:00' AND '10:00:00' OR
 CAST(Time_of_Day AS TIME ) BETWEEN '17:00:00' AND '21:00:00')
GROUP BY State_Name
ORDER BY fatal_count ASC

--OBJ 14)Which states experienced the highest number of fatal accidents during rainy weather at night?
SELECT TOP 1 State_Name,SUM(CASE WHEN Accident_Severity='FATAL' THEN 1 ELSE 0 END)/COUNT(*) AS fatal_count
FROM dbo.accident_prediction_india
WHERE Weather_Conditions='RAINY' AND 
      CAST(Time_of_Day AS TIME )>'20:00:00' OR CAST(Time_of_Day AS TIME )<'05:00:00'
GROUP  BY State_Name
ORDER BY  fatal_count DESC;

-- OBJ 15)Rank states based on the percentage change in fatality rate between two consecutive years 2022,2023.

WITH yearly_fatality AS (
    SELECT 
        State_Name,
        YEAR AS accident_year,
        COUNT(*) AS total_accidents,
        SUM(CASE WHEN Accident_Severity = 'FATAL' THEN 1 ELSE 0 END) AS fatal_accidents
    FROM dbo.accident_prediction_india
    WHERE YEAR IN (2022, 2023)
    GROUP BY State_Name, YEAR
),

pivot_table AS (
    SELECT 
        State_Name,
        MAX(CASE WHEN accident_year = 2022 THEN fatal_accidents * 1.0 / total_accidents END) AS rate_2022,
        MAX(CASE WHEN accident_year = 2023 THEN fatal_accidents * 1.0 / total_accidents END) AS rate_2023
    FROM yearly_fatality
    GROUP BY State_Name
)

SELECT 
    State_Name,
    rate_2022,
    rate_2023,
    (rate_2023 - rate_2022) * 100.0 / NULLIF(rate_2022, 0) AS percent_change
FROM pivot_table
ORDER BY percent_change DESC;
