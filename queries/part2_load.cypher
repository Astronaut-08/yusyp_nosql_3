// 1. Користувачі
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {id: toInteger(row.userId)})
SET u.gender = row.gender;

// 2. Професії
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (o:Occupation {id: toInteger(row.occupation)});

// 3. Вікові групи
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (a:AgeGroup {id: toInteger(row.age)});

// 4. Фільми
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {id: toInteger(row.movieId)})
SET m.title = row.title;

// 5. Жанри
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName});

// Індекси
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT occ_id IF NOT EXISTS FOR (o:Occupation) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT age_id IF NOT EXISTS FOR (a:AgeGroup) REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.id IS UNIQUE;
CREATE CONSTRAINT genre_name IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;

// Ребро Фільм - Жанр 
CALL apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row RETURN row",
    "MATCH (m:Movie {id: toInteger(row.movieId)})
    UNWIND split(row.genres, '|') AS genreName
    MATCH (g:Genre {name: genreName})
    MERGE (m)-[:BELONGS_TO]->(g)",
    {batchSize: 1000, parallel: false}
);

// Ребро Користувач - професія і вік 
CALL apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row RETURN row",
    "MATCH (u:User {id: toInteger(row.userId)})
    MATCH (o:Occupation {id: toInteger(row.occupation)})
    MATCH (a:AgeGroup {id: toInteger(row.age)})
    MERGE (u)-[:WORKS_AT]->(o)
    MERGE (u)-[:FALLS_INTO]->(a)",
    {batchSize: 1000, parallel: false}
);

// Ребро Користувач - фільм 
CALL apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
    "MATCH (u:User {id: toInteger(row.userId)})
    MATCH (m:Movie {id: toInteger(row.movieId)})
    MERGE (u)-[r:RATED]->(m)
    SET r.rating = toInteger(row.rating),
        r.timestamp = toInteger(row.timestamp)",
    {batchSize: 1000, parallel: false}
);
