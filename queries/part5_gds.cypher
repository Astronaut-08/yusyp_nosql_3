// 5.1

// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND elementId(m1) < elementId(m2)
WITH m1, m2, count(u) AS weight
WHERE COUNT { (m1)<-[:RATED]-() } > 20
  AND COUNT { (m2)<-[:RATED]-() } > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

!!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!
CALL gds.pageRank.stream('movieGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS name, score
ORDER BY score DESC;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;


// 5.2

// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating > 4 AND r2.rating > 4 AND elementId(u1) < elementId(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 25000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: створюємо проєкцію
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

!!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!
CALL gds.louvain.stream('userSimilarity')
YIELD nodeId, communityId
WITH communityId, count(nodeId) AS clusterSize
RETURN communityId, clusterSize
ORDER BY clusterSize DESC
LIMIT 10;

// ТОП фільмів для групи
CALL gds.louvain.stream('userSimilarity')
YIELD nodeId, communityId
WITH communityId, gds.util.asNode(nodeId) AS u, count(nodeId) AS clusterSize
MATCH (u)-[r:RATED]->(m:Movie)-[:BELONGS_TO]->(g:Genre)
WHERE r.rating >= 4
WITH communityId, g.name AS genreName, count(m) AS genreVotes, clusterSize
WITH communityId, genreName, sum(genreVotes) AS totalVotes, clusterSize
ORDER BY clusterSize, totalVotes DESC
WITH communityId, collect({genre: genreName, votes: totalVotes})[0..3] AS top
RETURN communityId, top;

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;


// 5.3

// Проєкція потрібна та сама, що і для Louvain — пересотворіть, якщо видалили
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating > 4 AND r2.rating > 4 AND elementId(u1) < elementId(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

!!! МІСЦЕ ДЛЯ ВАШОГО КОДУ !!!
MATCH (source:User {id: 4411})
MATCH (target:User {id: 10})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target,
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds, totalCost
RETURN [nodeId IN nodeIds | gds.util.asNode(nodeId).id] AS route, totalCost;

CALL gds.graph.drop('userGraph');