CREATE DATABASE healthcare_project;
USE healthcare_project;
CREATE TABLE hospital_data (
    encounter_id BIGINT,
    patient_nbr BIGINT,
    race VARCHAR(50),
    gender VARCHAR(20),
    age VARCHAR(20),
    admission_type_id INT,
    discharge_disposition_id INT,
    admission_source_id INT,
    time_in_hospital INT,
    payer_code VARCHAR(20),
    medical_specialty VARCHAR(100),
    num_lab_procedures INT,
    num_procedures INT,
    num_medications INT,
    number_outpatient INT,
    number_emergency INT,
    number_inpatient INT,
    diag_1 VARCHAR(20),
    diag_2 VARCHAR(20),
    diag_3 VARCHAR(20),
    number_diagnoses INT,
    max_glu_serum VARCHAR(20),
    A1Cresult VARCHAR(20),
    insulin VARCHAR(20),
    medication_change VARCHAR(10),
    diabetesMed VARCHAR(10),
    readmitted VARCHAR(10)
);
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\diabetic_data.csv'
INTO TABLE hospital_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT * FROM hospital_data;

#CHECK MISSING VALUES
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN race = '?' THEN 1 ELSE 0 END) AS missing_race,
SUM(CASE WHEN medical_specialty = '?' THEN 1 ELSE 0 END) AS missing_medical_specialty,
SUM(CASE WHEN payer_code = '?' THEN 1 ELSE 0 END) AS missing_payer_code
FROM hospital_data;

#AGE CONVERSION INTO NUMERIC MID POINT
ALTER TABLE hospital_data ADD COLUMN age_mid INT;
UPDATE hospital_data 
SET age_mid = 
CASE
WHEN age = '[0-10)' THEN 5
WHEN age = '[10-20)' THEN 15
WHEN age = '[20-30)' THEN 25
WHEN age = '[30-40)' THEN 35
WHEN age = '[40-50)' THEN 45
WHEN age = '[50-60)' THEN 55
WHEN age = '[60-70)' THEN 65
WHEN age = '[70-80)' THEN 75
WHEN age = '[80-90)' THEN 85
WHEN age = '[90-100)' THEN 95
END;

# KPIs
## READMISSION RATE
SELECT ROUND(SUM(CASE WHEN readmitted = '>30' THEN 1 ELSE 0 END) * 100.0
/ COUNT(*),2) AS readmission_rate_30_days FROM hospital_data;

## AVG LENGTH OF STAY
SELECT AVG(time_in_hospital) AS avg_stay
FROM hospital_data;

## HIGH MEDICATION IMPACT
SELECT 
CASE WHEN num_medications <20 THEN 'HIGH MEDICATION'
ELSE 'NORMAL MEDICATION' END AS medication_group, COUNT(*) AS total, 
ROUND(SUM(CASE WHEN readmitted = '>30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS readmission_rate_30_days
FROM hospital_data
GROUP BY medication_group;

## Readmitted patients under 30 days out of total patients
SELECT 
    COUNT(*) AS total_patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_30,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) 
        * 100.0 / COUNT(*),
        2
    ) AS readmission_rate_30_days
FROM hospital_data;

## Readmission rate by AGE group
SELECT age, COUNT(*) AS total_patients,
SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_30,
ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS readmission_rate
FROM hospital_data
GROUP BY age
ORDER BY readmission_rate DESC;

## DOES LENGTH OF STAY IMPACT READMISSION
SELECT CASE WHEN time_in_hospital <=3 THEN 'Short stay (1-3)' 
WHEN time_in_hospital BETWEEN 4 AND 7 THEN 'Medium stay (4-7)'
ELSE 'Long stay (8+)' END AS stay_category,
COUNT(*) AS total_patients,
ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS readmission_rate
FROM hospital_data
GROUP BY stay_category
ORDER BY readmission_rate DESC;

## MEDICATION INTENSITY VS READMISSION
SELECT CASE WHEN num_medications <= 10 THEN 'Low Medication' 
WHEN time_in_hospital BETWEEN 11 AND 20 THEN 'Medium Medication'
ELSE 'High Medication' END AS medication_category,
COUNT(*) AS total_patients,
ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS readmission_rate
FROM hospital_data
GROUP BY medication_category
ORDER BY readmission_rate DESC;

## COMBINING AGE + MEDICATION + STAY
SELECT age, COUNT(*) AS total_patients,
CASE WHEN time_in_hospital > 8 THEN 'Long stay' ELSE 'Other' END AS stay_category,
ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS readmission_rate
FROM hospital_data
GROUP BY stay_category, age
HAVING stay_category = 'Long stay'
ORDER BY readmission_rate DESC;

## READMISSIONS IMPACT FROM EMERGENCY
SELECT 
    CASE 
        WHEN number_emergency = 0 THEN 'No Emergency Visit'
        WHEN number_emergency BETWEEN 1 AND 2 THEN '1-2 Emergency Visits'
        ELSE '3+ Emergency Visits'
    END AS emergency_category,
    COUNT(*) AS total_patients,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS readmission_rate
FROM hospital_data
GROUP BY emergency_category
ORDER BY readmission_rate DESC;
