--Write an explanation of what is happening in each query (as a sql comment or in the readme). Be sure to reference the data model in your explanations.



-- 1.	Show all customers whose last names start with T. Order them by first name from A-Z.
SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name LIKE 'T%'
ORDER BY first_name;
/* This query selects the customer_id, first_name, and last_name columns from the
   customer table of the data model. Then, it filters results to only select 
   where the last_name column begins with 'T'. Finally, we sort by first_name, A-Z*/



-- 2.	Show all rentals returned from 5/28/2005 to 6/1/2005
SELECT rental_id, return_date
FROM rental
WHERE return_date > '2005-05-27 23:59:59'
AND return_date < '2005-06-02 00:00:01'
ORDER BY return_date;
/* This query selects the rental_id and return_date columns from the rental table of the data model.
   Query is filtered where the return date is greater than 2005-05-27 23:59:59, but
   less than 2005-06-02 00:00:01. This gives us results between 5/28 and 6/1.
   Finally, the results are ordered by return_date to make checking our results easier*/



-- 3.	How would you determine which movies are rented the most?
        /*I would want to select the 'inventory_id' column from the rental table 
			because that likely represents one movie. Then, I can group by inventory_id  
			and ask for a count to count how many times that movie was rented.
			I then sort by the count in descending order to view the ids
    		        with the highest count (i.e. rented the most often).;*/

-- original query
/*SELECT inventory_id, count(*)
FROM rental
GROUP BY inventory_id
ORDER BY count DESC; --4580 rows*/

/*   According to the data model, I can also join on inventory to get the inventory_id
     Joining by inventory_id will allow me to connect this result to the film table
     The film table will allow me to get the actual film title. Modifying in this way
     will allow me to have a more specific sense of which movies are rented most */

-- modified query
SELECT f.title, count(inventory_id) AS rental_count
FROM rental
JOIN inventory AS i USING (inventory_id)
JOIN film AS f USING (film_id)
GROUP BY inventory_id, f.title
ORDER BY rental_count DESC; --4580 rows



-- 4.	Show how much each customer spent on movies (for all time). Order them from least to most.
SELECT customer_id, SUM(amount) AS amount_spent
FROM payment
GROUP BY customer_id
ORDER BY SUM(amount);
/*  In this query, I am selecting the customer_id column as well as the aggregated sum of
    the 'amount' column from the payment table. I am grouping by the customer_id and
    then ordering by the sum to see how much customers spent. I also aliased the amount
    to make it extra clear.*/



-- 5.	Which actor was in the most movies in 2006 (based on this dataset)? Be sure to alias the actor name and count as a more descriptive name. Order the results from most to least.
--Need actor table to get the names of the actors
--Need film_actor table associate the actors with a film (film_ids)
--Need film table to connect the actors to film_id and release_year
SELECT a.actor_id, 
	   CONCAT(a.First_Name , ' ' , a.Last_Name) AS actor_name,
	   COUNT(f.film_id) AS film_count,
	   film.release_year
FROM actor AS a JOIN film_actor AS f USING (actor_id)
JOIN film USING (film_id)
WHERE release_year=2006
GROUP BY a.actor_id, film.release_year
ORDER BY film_count DESC;
-- Gina Degeneres was in the most movies in 2006. Gina was in 42 movies, to be precise. 

/* In this query, I am joining the film_actor table to the actor table, using 'actor_id'.
According to the data model, this was a shared variable. I was then able to join the film
table to my result using the 'film_id' variable. I filted this entire result by release
year being 2006. I aggregated by film count, grouping by the actor_id and the release year.
This allowed me to see which actor was in the most movies. Finally, I ordered by the 
film_count to better see who was in the most movies. I only selected actor_id, actor_name,
film_count, and release_year. */



-- 6.	Write an explain plan for 4 and 5. Show the queries and explain what is happening in each one. Use the following link to understand how this works http://postgresguide.com/performance/explain.html 

--Explain plan for #4
EXPLAIN ANALYZE 
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
GROUP BY customer_id
ORDER BY SUM(amount);

--Query plan shows that the start-up cost before first row 
  --- can be returned is 362.06. The total cost to return all rows is 363.56.
--There are 599 rows and the actual time to return them all was 10.077
--The planner sorted by sum(amount)
--The planner used the 'quicksort' method for the sorting
--The total cost to aggregate the rows was 334.43 and actual time was 9.834 for 599 rows
--The planner grouped by customer_id and used 297kb of memory
--The planner scanned the payment table, which has 14596 rows. 
  ---The total cost to do that was 253.96 and actual time was 1.710
--The total planning time was 0.128ms and the entire query to 10.200ms to execute

--Explain plan for #5
EXPLAIN ANALYZE
SELECT a.actor_id, 
	   CONCAT(a.First_Name , ' ' , a.Last_Name) AS actor_name,
	   COUNT(f.film_id) AS film_count,
	   film.release_year
FROM actor AS a JOIN film_actor AS f USING (actor_id)
JOIN film USING (film_id)
WHERE release_year=2006
GROUP BY a.actor_id, film.release_year
ORDER BY film_count DESC;

--QUERY PLAN shows that the start-up cost before the first row was 250.26 and the 
   --- total cost was 250.76 for 200 rows; the actual time was 19.604
--The planner sorted on the count of the film_id column in descending order, using
  ---the quick sort method, taking up 40kb of memory
--The planner estimated 242.62 for this aggregation of 200 rows and it actually took
  ---19.300
--The planner grouped by the actor_id column and then by the release_year
  ---This took 64kb of memory
--The planner joined on the condition of f.film_id=film.film_id, creating 5462 rows
--The planner then joined on the condition of f.actor_id=a.actor_id
--The planner scanned on the film_actor table for 5462 which took an actual time of 
  --1.334; the batch took 18kb in memory to compile
--The planner scanned the actor table taking 48kb memory
--The planner scanned on film with an actual time of 1.146
--The planner filtered by release year, equaling 2006
--The took the planner 2.040 ms and the total query execution time was 19.905 ms



-- 7.	What is the average rental rate per genre?
-- The following query will display the average rental rate per genre
-- The 'Games' genre has the highest average rate ($3.25), followed by
-- 'Travel' and 'Sci-Fi' as ($3.24) and ($3.22), respectively

SELECT name AS genre, ROUND(AVG(rental_rate),2) AS avg_rental_rate
FROM film_category
JOIN film USING (film_id)
JOIN category USING (category_id)
GROUP BY genre
ORDER BY avg_rental_rate DESC;

/* In this query, I joined the film table to the film_category table, using the common
'film_id' variable. I then joined the category table by using the common 'category_id'
variable. I grouped by the alias 'genre' after aggregated by average rental rate. To
simplify the result, I only selected 'genre' and 'avg_rental_rate'. */



-- 8.	How many films were returned late? Early? On time?
--select variables we want
WITH return_label_t AS (SELECT f.film_id, i.inventory_id, f.rental_duration, 
		r.rental_date, r.return_date,
		--create new variable to determine how long something was rented
		DATE_PART('day',return_date-rental_date) AS days_rented,
		--new variale to determine whether returned on time or not
		CASE WHEN DATE_PART('day',return_date-rental_date) < rental_duration THEN 'Early'
		WHEN DATE_PART('day',return_date-rental_date) = rental_duration THEN 'On Time'
		ELSE 'Late' END
			AS return_label
--INTO return_label_t
-- Retrieve from the film table and join with inventory/rental
FROM film AS f
JOIN inventory AS i USING (film_id)
JOIN rental AS r USING (inventory_id)
ORDER BY inventory_id)

-- Select newly created variable from temporary table
	SELECT return_label, COUNT(*) AS return_count
	FROM return_label_t
	GROUP BY return_label
	ORDER BY return_count DESC;

-- 7738 Movies were returned early, 6586 were returned late, and 1720 movies were returned on time

/* This query involved many steps, and I went through several revisions. I ended up using
the sub-query method. First, I determined which tables I needed by referencing the data
model. I knew I needed film, inventory, and rental. I joined inventory to film using the
film_id and then I joined rental using inventory_id. I created a new variable called
'days_rented' where I substracted the rental date from the return date. I compared this
to the 'duration' variable to create a new variable, where I categorized things as 'early',
'on time', or 'late'. I made all of this a sub-query block that I called 'return_label_t'.
Finally, I was able to query from that table to select the return_label variable I had
created. I aggregated by count, grouped by return label, and then ordered by the count.*/



-- 9.	What categories are the most rented and what are their total sales?
SELECT c.name AS genre, SUM(p.amount) AS total_sales, COUNT(r.rental_id)
FROM category AS c
JOIN film_category AS fc USING (category_id)
JOIN inventory AS i USING (film_id)
JOIN rental AS r USING (inventory_id)
JOIN payment AS p USING (rental_id)
GROUP BY genre
ORDER BY count DESC;

-- Sports, animation, and action are the top three most rented (1st, 2nd, 3rd, respectively). Their total sales are as follows:
-----Sports=$4892.19, animation=$4245.31, action=$3951.84

/* For this query, I had to utilize a string of joins to get the variables I needed. I 
joined film_category to category using 'category_id'. This allowed me to join inventory 
table by film_id, and then rental table by inventory_id and then the payment table by
the rental_id. I grouped my query by the alias 'genre', which was created from the name
column of the category table. I aggregated by the sum of amount to get the total sales
and then count of rental_id to determine movies rented. I ordered everything by this
count to determine which movies were rented the most. */



-- 10.	Create a view for 8 and a view for 9. Be sure to name them appropriately. 

-- View for #8
CREATE VIEW return_items AS
WITH return_label_t AS (SELECT f.film_id, i.inventory_id, f.rental_duration, 
		r.rental_date, r.return_date,
		--create new variable to determine how long something was rented
		DATE_PART('day',return_date-rental_date) AS days_rented,
		--new variale to determine whether returned on time or not
		CASE WHEN DATE_PART('day',return_date-rental_date) < rental_duration THEN 'Early'
		WHEN DATE_PART('day',return_date-rental_date) = rental_duration THEN 'On Time'
		ELSE 'Late' END
			AS return_label
--INTO return_label_t
-- Retrieve from the film table and join with inventory/rental
FROM film AS f
JOIN inventory AS i USING (film_id)
JOIN rental AS r USING (inventory_id)
ORDER BY inventory_id)

-- Select newly created variable from temporary table
	SELECT return_label, COUNT(*) AS return_count
	FROM return_label_t
	GROUP BY return_label
	ORDER BY return_count DESC;

-- View for #9
CREATE VIEW category_sales AS
SELECT c.name AS genre, SUM(p.amount) AS total_sales, COUNT(r.rental_id)
FROM category AS c
JOIN film_category AS fc USING (category_id)
JOIN inventory AS i USING (film_id)
JOIN rental AS r USING (inventory_id)
JOIN payment AS p USING (rental_id)
GROUP BY genre
ORDER BY count DESC;



-- Bonus:
-- Write a query that shows how many films were rented each month. Group them by category and month. 
