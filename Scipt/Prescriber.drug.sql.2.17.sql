--Question 1
-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT prescriber.npi, SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi
Order BY total_claims DESC
LIMIT 3;
--Answer npi 1881634483, total claims 99707
	
	
--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT p.nppes_provider_first_name AS name, p.nppes_provider_last_org_name AS last_name, specialty_description, SUM(pres.total_claim_count) AS total_claims
FROM prescriber AS p
INNER JOIN prescription AS pres
ON p.npi = pres.npi
GROUP BY p.nppes_provider_first_name, p.nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC
LIMIT 10;
--Answer Bruce Pendley, Family Practice, 99707

--Question 2 
--a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT p.specialty_description, SUM(pres.total_claim_count) as total_claim_count
FROM prescriber AS p
INNER JOIN prescription AS pres
ON p.npi = pres.npi
GROUP BY p.specialty_description
ORDER BY total_claim_count DESC;
--Answer Family Practice - 9,752,347

-- b. Which specialty had the most total number of claims for opioids?
SELECT prescriber.specialty_description, drug.opioid_drug_flag,
SUM(prescription.total_claim_count) AS total_claim
From prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag
ORDER BY SUM(total_claim_count) DESC
LIMIT 3;
--Answer: Nurse Practitioner - 900845


--Question 3
--a. Which drug (generic_name) had the highest total drug cost?
SELECT drug.generic_name, prescription.total_drug_cost
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
GROUP BY drug.generic_name, prescription.total_drug_cost
ORDER BY total_drug_cost DESC;
--Answer: Pirfenidone - $2,829,174.30

--b. Which drug (generic_name) has the hightest total cost per day?**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, ROUND((SUM(prescription.total_drug_cost))/(SUM(prescription.total_day_supply)),2) AS sum_total_drug_cost_per_day
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
GROUP By drug.generic_name
ORDER BY sum_total_drug_cost_per_day DESC
LIMIT 10;
--Answer: C1 ESTERASE IMHIBITOR - $3495.22

--Question 4
--  a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name,
  CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
   ELSE 'neither' END AS drug_type
FROM drug;
--Answer 

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
	SUM(MONEY(prescription.total_drug_cost))
FROM drug
INNER JOIn prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY SUM(MONEY(prescription.total_drug_cost)) DESC;
--Answer: Opioid

--Question 5
-- a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT count(cbsa) as Count_CBSAs_in_TN
FROM cbsa
INNER JOIN fips_county
ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN';
--Answer 42

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa, SUM(population) as total_population
FROM cbsa
INNER JOIN population
on cbsa.fipscounty = population.fipscounty
GROUP BY cbsa
ORDER BY total_population;
--Answer: 
--34980 - 1,830,410 - Largest
--34100 - 116,352 - Smallest

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT population.population, fips_county.county
FROM population
LEFT JOIN CBSA
USING (fipscounty)
LEFT JOIN fips_county 
USING (fipscounty)
WHERE cbsa.cbsa IS NULL
ORDER BY population.population DESC;
--Answer Sevier, 95523

--Question 6
--a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
Select drug_name, SUM(total_claim_count) as total_claim_count
From prescription
Where total_claim_count >= 3000
Group By drug_name


--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
Select prescription.drug_name, opioid_drug_flag, SUM(total_claim_count) as total_claim_count
From prescription
Left Join drug
on prescription.drug_name = drug.drug_name
Where total_claim_count >= 3000
Group By prescription.drug_name, opioid_drug_flag;


--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
Select prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescription.drug_name, opioid_drug_flag, SUM(total_claim_count) as total_claim_count
From prescription
Left Join drug
on prescription.drug_name = drug.drug_name
Left Join prescriber
on prescription.npi = prescriber.npi
Where total_claim_count >= 3000
Group By prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescription.drug_name, opioid_drug_flag


--Question 7
--The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--cross join hint

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT drug.drug_name, prescriber.npi
FROM prescriber
CROSS JOIN drug
WHERE prescriber.specialty_description ILIKE 'pain management'
AND prescriber.nppes_provider_city ILIKE 'nashville' AND drug.opioid_drug_flag = 'Y';



--  b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi, drug.drug_name, SUM(prescription.total_claim_count)
FROM prescriber
CROSS JOIN prescription
CROSS JOIN drug
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
Group BY prescriber.npi, drug.drug_name

--  c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name,
 	(SELECT(COALESCE(SUM(prescription.total_claim_count),0))
	FROM prescription
	WHERE prescription.npi = prescriber.npi
	AND prescription.drug_name = drug.drug_name) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON drug.drug_name = prescription.drug_name
WHERE prescriber.specialty_description ILIKE 'Pain Management'
AND prescriber.nppes_provider_city ILIKE 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
GROUP BY drug.drug_name, prescriber.npi
ORDER BY total_claims DESC;



