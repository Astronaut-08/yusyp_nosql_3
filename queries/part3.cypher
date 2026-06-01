// Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0:
MATCH ()-[r:RATED]->(m:Movie)-[:BELONGS_TO]->(g:Genre {name: "Thriller"}) 
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4
RETURN m.title, avgRating;

// Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам:
MATCH (p:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH p, count(r) AS ratedCount
WHERE ratedCount > 50
RETURN p.id, ratedCount;

// Запит 3. Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4):
MATCH (u1:User {id: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {id: 2})
WHERE r1.rating >=4 AND r2.rating >= 4
RETURN m.title, u1.id, u2.id;

// Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок:
MATCH ()-[r:RATED]->(m:Movie)-[:BELONGS_TO]->(g:Genre)
WITH avg(r.rating) AS avgRating, count(r) AS countRating, g
WHERE avgRating >= 4 AND countRating >= 50
RETURN g.name AS genreName, avgRating, countRating;

// Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача знайти фільми, 
// які він ще не дивився, але високо оцінили користувачі з подібними смаками:
MATCH (u1:User {id: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND u2 <> u1
WITH u1, u2, count(m) AS commonFilmCount
WHERE commonFilmCount >= 15
MATCH (u2)-[r3:RATED]->(rec:Movie)
WHERE r3.rating = 5 AND NOT (u1)-[:RATED]->(rec)
RETURN DISTINCT u1.id AS userId, rec.id AS filmId, rec.title AS filmName;

// Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами
// через спільні фільми:
MATCH (u1:User {id: 1}), (u2:User {id: 2})
MATCH path = shortestPath((u1)-[:RATED*]-(u2))
WHERE ALL(
    n IN nodes(path)[1..-1]
    WHERE 'Movie' IN labels(n) OR 'User' IN labels(n)
)
RETURN path, length(path);