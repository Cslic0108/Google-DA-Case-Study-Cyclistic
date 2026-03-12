## 1. Project Overview

### 1.1 The Business Challange:

Cyclistic is a bike-share company in Chicago, currently operates a fleet of 5,800+ bicycles and 600+ docking stations. The Director of Marketing believes the company’s future depends on maximizing the number of annual memberships. My task is to identify the behavioral differences between **casual riders** and **annual members** to drive conversions.

### 1.2 Stakeholders & Audience:

- **Primary Stakeholder**: Lily Moreno (Director of Marketing), responsible for approving the marketing strategy.
- **Marketing Analytics Team**: Responsible for data collection and analysis.
- **Executive Team**: Decision-makers focused on long-term profitability.

## 2. Data Preparation & Enviroment

### 2.1 Data source:

The dataset used for this analysis is the historical trip data provided by Cyclistic. The data is made available by Motivate International Inc. under this agreement. [Links]( https://divvybikes.com/data-license-agreement.)\
The data is hosted on a secure AWS S3 bucket as the links below.\
[Datasets](https://divvy-tripdata.s3.amazonaws.com/index.html)

For this study, I selected 12 monthly CSV files covering the period from January 2025 to December 2025.

 The data is structured in a tabular format, with each record representing a single trip. Key column include ride_id, started_at, start_station_name, and member_casual.

### 2.2 Data Credibility

To ensure the intergrity of the insights, the dataset was validated against the **ROCCC** framework.

- Reliable: The data was generated directly by the bike-share system’s backend, minimizing human error.
- Original: This is a primary data collected firstr-hand by the service provider.
- Comprehensive: It provides all necessary dimensions such as duration, location and usertype, which is important for answering the business questions.
- Current: The 2025 records reflect the most recent market trends and usage patterns.
- Cited: The data is used under the Data License Agreement provided by the City of Chicago.

### 2.3 Technical Infrastructure

The total volume for 2025 exceeds 5.5 million rows, a spreadsheet software like Excel was insufficient for performance nd scalability. Therefore, this study is using **MySQL 8.0** for further analysis. 

Using a relational Database Management System allows for strict data type definitions and the enforcement of primary keys to prevent duplicate entriies. MySQL also enables the use of index and clistering, which significantly reduce execution time for complex aggregations on multi-million-row datasets.

### 2.4 Data Schema

Observation: During the data ingestion via Python, I observed a parsing error**,** the entire row of CSV data was being stored in the `ride_id` column, leaving all subsequent columns as `NULL` . To resolve this, I recofigured the ETL script explicitly defining the `fieldsTerminatedBy: ','`  and switched to a `VARCHAR` staging schema to prevent further data loss.

Final Table Structure:

- Primary Key: `ride_id` (Ensures each trip is unique).
- Temporal Data: `started_at`, `ended_at` (Converted to `DATETIME` for time-series analysis).
- Categorical Data: `rideable_type`, `member_casual` (Standardized strings).
- Geospatial Data: `start_lat`, `start_lng`, etc. (Stored as `DECIMAL(10, 8)` for coordinate precision).

## 3. Data Process

### 3.1 Field Type Reformatting & Optimization

After ensuring that all raw data was succesfully imported, I executed a schema hardening process to convert `VARCHAR` raw string into structured data type for further analysis.  
[Converting strings to `DATETIME`](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)

During the reformating phase, I’ve identify some of the data is empty stings, these data need to be standartize before taking further action. This help ensuring data intergrity.  
[Cleanup NULL](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)

Once cleaning the NULL value, I converted latitude and longitude coordinates from strings to DECIMAL(10, 8).  
[Converting strings to `DECIMAL`](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)

### 3.2 Logical Validation

After reformatting field type, I applied some filters to ensure the dataset represents gunuine user behavior.  
To identify trips with end time earlier than start time, I applied following filter to detect the inconsistent records.  
[Inconsistent travel record](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)  
output:  
| inconsist_travel_count |
| --- |
| 29 |

To prevent the analysis affected by accidental dockings or faulty equipment, I applied a 60 second threshold. Trips lasting less than one minute were classified as ‘non-utilization events’ and excluded from the final analysis to ensure a more accurate representative of average trip durations.  
[Trip Duration Validation](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)  
output:  
| less_than_60 |
| --- |
| 146923 |

### 3.3 Clean Dataset

To ensure the reliability of the behavioral insights. It was important to remove anomalous record. These inconsistencies could brought impact to the analysis. leading a inaccurate conclusions. A comparitive analysis between the raw dataset and cleaned dataset reveal a significant shift in average trip durations, comfirming that the removal of noise is essential for the analysis.

First, calculate average duration with raw data.  
[Calculate average duration with raw data](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)  
output:  
| member_casual | total_rows | raw_avg_duration |
| --- | --- | --- |
| member | 3553497 | 11.8440 |
| casual | 1999497 | 22.1086 |

Then calculate the average duration with cleaned data.  
[Calculate average duration with cleaned data](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)  
output：  
| member_casual | total_rows | cleaned_avg_duration |
| --- | --- | --- |
| member | 3553497 | 12.57 |
| casual | 1999497 | 23.51 |

After comparing the average duration time between raw data and cleaned data, the average trip lengths adjusted as follows:

Member: Increased from 11.84 to 12.57 minutes.

Casual: Increaased from 22.11 to 23.51 minutes.

This shows that it is essential to exclude these noise to prevent downward bias in the final analysis.

### 3.4 Create the Final Data

I created a View that filters out all identified anomalies. This ensures that all future queries in the Analyze phase are performed on a consistent, high-integrity data pool without the need to re-apply filters.
[Create final data](https://github.com/Cslic0108/Google-DA-Case-Study-Cyclistic/blob/main/Data_Process.sql)


## 4. Analyze

### 4.1 Performance Optimization

**4.1.1 Database Indexing**

Before analyzing data, I’ve notice that current size of data was massize(5.5 million). To enchance the performance of quering, I implemented database indexing. By creating B-tree indexes on the `start_at` and `member_casual` columns, this would help to transit the workload from high-latency disk scans to index-based lookups.

- Creating index

```sql
 CREATE INDEX idx_started_at ON main_data(started_at);
 CREATE INDEX idx_member_casual ON main_data(member_casual);
```

After creating index, I run a EXPLAIN command to audit the query optimizer’s behavior.

- Indexing validation

```sql
EXPLAIN SELECT member_casual, COUNT(*) 
FROM v_clean_trips 
WHERE started_at > '2025-01-01' 
GROUP BY member_casual;
```

output:

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | SIMPLE | main_data | NULL | index | idx_started_at,idx_member_casual | idx_member_casual | 203 | NULL | 5405791 | 16.66 | Using where |

Despite the high row count of the result, the indexes remain helpful for the dataset It accelerate subsequent aggregations and ensure near-instant response times for the queries in following analysis.

**4.1.2 Analytical Schema Aggregation**

To bridge the gap between large-scale data and interactive visualization, I turn the 5.5 million record into a multi-dimensional aggregate schema. IBy using MySQL, I pre-calculate Trip counts and average durations, extract critical dimension such as Month, Day of Week, and Hour of Day from standard timestamps. These pre-process steps will give us a useful table for further analysis and visualizations.

```sql
SELECT 
    member_casual,
    DAYOFWEEK(started_at) AS day_of_week,
    HOUR(started_at) AS hour_of_day,
    MONTH(started_at) AS month_num,
    rideable_type,
    COUNT(*) AS trip_count,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, started_at, ended_at)/60), 2) AS avg_duration
FROM v_clean_trips
GROUP BY member_casual, day_of_week, hour_of_day, month_num, rideable_type;
```

output:

| member_casual | day_of_week | hour_of_day | month_num | rideable_type | trip_count | avg_duration |
| --- | --- | --- | --- | --- | --- | --- |
| member | 3 | 17 | 1 | classic_bike | 753 | 13.03 |
| member | 7 | 15 | 1 | electric_bike | 603 | 11.36 |
| … | … | … | … | … | … | … |

### 4.2 Monthly Trip Trend

Data Visualization: Tableau

<img width="1173" height="635" alt="Monthly Trip Trend" src="https://github.com/user-attachments/assets/0e24dcd1-4344-4f7c-b4ba-648cfc44c77b" />

This line chart shows that both Casual riders and Members reach their peak usage during June to August, likely driven by warmer weather and peak travel seasons. Conversely, there is a sharp decline from October to December, which strongly suggests that bike usage is highly dependent on seasonal temperature changes in Chicago.

### 4.3 Week Trip Distribution

Data Visualization: Tableau

<img width="1325" height="635" alt="Week Trip Distribution" src="https://github.com/user-attachments/assets/36e431a6-9498-4519-99f0-08aafe23bb16" />

Based on the weekly bar graph, a distinct behavioral divide is observed between two segments. During weekdays, Casual ridership remains significantly lower than Members. In contrast, the gap between the two groups narrows during weekend, with Casual ridership reaching its peak. This trend reinforces the conclusion that Casual riders primarily utilize the service for recreational use, whereas Members rely on it as a functional daily transportation solution.

### 4.4 Peak Usage Periods

Data Visualization: Tableau

<img width="1393" height="635" alt="Peak Usage Periods" src="https://github.com/user-attachments/assets/4ddad52e-9520-4484-8457-23f9951089c9" />

The hourly chart clearly shows that Member activity peaks precisely at 0800 and 1700, providing strong evidence for our earlier conclusion that members primarily use the service for daily commuting.

For Casual riders, their usage gradually builds throughout the day, peaking at 1700, likely driven by afternoon recreational activities. An interesting details is that around midnight, Casual ridership actually exceeds Member ridership. This suggest that during hours when public transit is limited, Casual riders are more likely to turn bike-sharing as a on-demand transportation solution.

### 4.5 Ride Duration

Data Visualization: Tableau

<img width="404" height="635" alt="Ride Duration (1)" src="https://github.com/user-attachments/assets/66d20bec-e93e-4ce8-8b2b-c85cac26d9c4" />

While member take more frequent trips, Casual riders spend twice as much time on each ride. Segmenting this behavior by bike type provides additional insihts into user intent.

<img width="556" height="670" alt="Trip Duration by Rideable Type (1)" src="https://github.com/user-attachments/assets/c7db0f27-cbe2-48fd-a5b7-c1d17bb48831" />

When it come to Classic Bike, the average duration for casual riders is more than twice that if Members. This suggest that when choosing classic bikes, casual rider are likely engageing in relaxed activities where time is not a primary constraint.

For electric bikes, the trip duration for both groups decreases and the gap narrows. This shows that they both  choose electric bike for efficiency-driven usage, potentially due to the motorized speed of electric bike.

### 4.6 Geospatial analysis

Given that the multi-dimensional aggrgate table focused on temporal and catogorical trends, I exported a seperate geospatial dataset for location-based analysis. This allows me to make a high-precesion station mapping without compromising the performance of the core analytical schema.

```sql
SELECT 
    start_station_name,
    member_casual,
    AVG(start_lat) AS lat,
    AVG(start_lng) AS lng,
    COUNT(*) AS trip_count
FROM v_clean_trips
WHERE start_station_name IS NOT NULL 
  AND start_station_name <> ''
  AND start_lat IS NOT NULL
GROUP BY start_station_name, member_casual;
```

output：

| start_station_name | member_casual | lat | lng | trip_count |
| --- | --- | --- | --- | --- |
| Wacker Dr & Washington St | member | 41.88314629 | -87.6372436 | 7086 |
| Halsted St & Wrightwood Ave | member | 41.92914322 | -87.64908031 | 8802 |
| … | …. | … | … | … |

Data Visualization: Tableau

The maps below illustrate the high-activity zones for both Casual riders and member.

<img width="1374" height="1099" alt="Dashboard 1" src="https://github.com/user-attachments/assets/3b66bc70-84b5-4f34-8bd0-2b2f84bd03c3" />

The comparison of active zones reveals a geographic divide between two segments. Casual riders are overwhelmingly concenstrated along the eastern lakefront and near major tourism landmarks, reinforcing thier preference on relaxing activities.

In contrast, Members activity is widely distributed across the city’s infrastructure. The top three locations with the highest ridership volume are stratergic transit hubs and business distinct such as the area arround Union Station. This reinforces the conclusion that their primary demand is driven by daily commuting.

### 4.7 Identification of Growth Potentials

<img width="1341" height="612" alt="Identification of Growth Potentials" src="https://github.com/user-attachments/assets/98996d83-efee-4314-a5ef-255de36f242a" />

By analyzing the total volume under the ‘ALL’ filter, I also identified four strategically significant locations: Theater on the Lake, Wells St & Concord Ln, Streeter Dr & Grand Ave, and Millennium Park.

These locations act as high-synergy zones where business and leisure traffic converge. For example, Millennium Park serves as a bridge between the commercial loop and the lakefront leisure belt. With a well-structured plan, these strategic stations could bring a huge revenue growth and long-term user value.

## 5. Share

To enable stakeholders to visually contrast the usage habits of both user segments, I devoloped a comprehensive dashboard intergrating monthly, weekly, hourly and geospatial dimensions. The centralized view allows stakeholders to identify the key insights efficiently .

<img width="1374" height="1099" alt="Dashboard 2" src="https://github.com/user-attachments/assets/d126b36c-5d42-45b8-9e11-23660628a8dd" />

## 6. Act & Recommendation

Building upon the comprehensive analysis of user behavioral and geographic hotspots, the following data-driven recommendations are proposed to drive Cyclistic’s strategic growth.

### 6.1 Seasonal Pass during Peak Month

By analyzing the monthly trend, we’ve notice that there is a peak usage from June to August. This presents a prime window for habit formation. 

I reccomend the marketing team launch a “Season Pass” during this period to lower down the cost for casual rider. If the casual riders develop a riding habit during this season, it is more likely they would convert into annual members in future.

### 6.2 Electric Bike Incentives during Weekend

The data shows that Casual riders predominantly ride during the weekends in leisure zones. The data also reflecting the fact that riding classic bike could be more costly since the overall trip duration would be longer.

I recommend introducing “Weekend Electric Bike Discount Vouchers” exclusive for members. This can lower the perceived barrier to entry. This stratergy showcase the immediate financial benefits and efficiency of a membership to casual riders, encouraging them to join the annual membership.

### 6.3 Targeted Marketing in High-potential Hubs

Based on the geospatial analysis, we’ve identified several stations where both Casual and Member activities overlap. To filter out one-time tourist and focus on high-value potential members, station like Wells St & Concord Ln and Millennium Park should be prioritize.These locations are stratergic transit hubs used by local residents and commuters.

I suggest Cyclistic deploy Price-Comparison Advertisements at these specific area. By highlighting the cost savings of an annual plan in an environment where bike-commuting is already the norm, the casual rider might be easily convinced that it is a more valuable investment if they get a membership instead of paying per ride.
