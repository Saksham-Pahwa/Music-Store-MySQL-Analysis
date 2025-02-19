Create database music_store;
Use music_store;

/********** Importing the required files for the analysis **********/


-- Ques. Who is the senior most employee based on job title ? 

select * from employee 
order by levels  desc limit 1;

-- Ans : So the senior most employee is Mohan Madan


-- Ques. Which countries have the most invoices ?

select billing_country, count(invoice_id) as Invoice_Count 
from invoice
group by billing_country 
order by Invoice_Count desc;

-- Ans : USA is the country with most invoices totaling at 131


-- Ques. What are top 3 values in the invoices ?

select total as invoice_value from invoice 
order by invoice_value desc limit 3;

-- Ans : So the top 3 values in the invoices are 23.7,19.8,19.8 respectively


/* Ques. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals */

select round(sum(total)) as Invoice_total, billing_city from invoice
group by billing_city 
order by Invoice_total desc;

-- Ans : Prague is th city with best customers all over the world


/* Ques. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money */

-- SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '')); --

select customer.customer_id,customer.first_name,customer.last_name, sum(invoice.total) as 
Total_spent from customer
JOIN invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by Total_spent desc
limit 1;

-- Ans : So the best customer is Frantisek Wichterl who spent 144.54


/* Ques. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A */

select distinct email,first_name,last_name from customer 
JOIN invoice on customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in( select track_id from track JOIN genre on track.genre_id = genre.genre_id where 
genre.name like 'ROCK' )
order by email ;

-- OR method to do the same 

select email as EMAIL , first_name as FIRST_NAME , last_name as LAST_NAME , genre.name as GENRE_NAME 
from customer
JOIN invoice on customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
JOIN track on track.track_id = invoice_line.track_id
JOIN genre on genre.genre_id = track.genre_id
where genre.name like 'ROCK'
order by email;

-- Ans : Run above query


/* Ques. Let's invite the artists who have written the most rock music in our dataset. Write a 
query that returns the Artist name and total track count of the top 10 rock bands  */

SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '')); 

select artist.artist_id, artist.name, count(artist.artist_id) as Number_of_Songs from track
JOIN album on track.album_id = album.album_id
JOIN artist on artist.artist_id = album.artist_id
JOIN genre on genre.genre_id = track.genre_id
where genre.name like 'ROCK' 
group by artist.artist_id , artist.name
order by Number_of_Songs desc
limit 10;

-- Ans : Run above query for result


/* Ques. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the 
longest songs listed first */

select name,milliseconds from track 
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;


/* Ques. Find how much amount spent by each customer on artists? Write a query to return 
customer name, artist name and total spent */

-- NOTE : Here the total spent refers to the Unit price * Quantity

With best_selling_artist as (
select artist.artist_id as artist_id, artist.name as artist_name, 
sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
from invoice_line
JOIN track on track.track_id = invoice_line.track_id
JOIN album on album.album_id = track.album_id
JOIN artist on artist.artist_id = album.artist_id
group by 1
order by 3 desc
limit 1 )

select customer.customer_id, customer.first_name, customer.last_name, best_selling_artist.artist_name,
round(sum(invoice_line.unit_price*invoice_line.quantity)) as Amount_spent
from invoice
JOIN customer on customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice_line.invoice_id = invoice.invoice_id
JOIN track on track.track_id = invoice_line.track_id
JOIN album on album.album_id = track.album_id
JOIN best_selling_artist on best_selling_artist.artist_id = album.artist_id
group by 1,2,3,4
order by 5 desc ;


/* 	Ques. We want to find out the most popular music Genre for each country. We determine the 
most popular genre as the genre with the highest amount of purchases. Write a query 
that returns each country along with the top Genre. For countries where the maximum 
number of purchases is shared return all Genres */

With Popular_Genre as 
( select count(invoice_line.quantity) as Purchases, customer.country, genre.name, genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY count(invoice_line.quantity) desc) as RowNo
from invoice_line
JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
JOIN customer on customer.customer_id = invoice.customer_id
JOIN track on track.track_id = invoice_line.track_id
JOIN genre on genre.genre_id = track.genre_id
group by 2,3,4
order by 2 asc , 1 desc )
Select * from Popular_Genre where rowno <= 1 ;


/* 	Ques. Write a query that determines the customer that has spent the most on music for each 
country. Write a query that returns the country along with the top customer and how 
much they spent. For countries where the top amount spent is shared, provide all 
customers who spent this amount */

With Country_with_Customer as
( select customer.customer_id , first_name , last_name , billing_country , round(sum(total)) as 
total_spending , 
ROW_NUMBER() OVER (PARTITION BY billing_country order by SUM(total) desc ) as RowNo
from invoice
JOIN customer on customer.customer_id = invoice.customer_id
group by 1,2,3,4 
order by 4 asc , 5 desc )
Select * from Country_with_Customer where rowno <=1 ;
