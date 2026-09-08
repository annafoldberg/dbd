-- Query 1: upcoming trips
select
    t.id,
    t.scheduled_departure_utc,
    t.status
from trips t
where t.route_id = :route_id
  and t.scheduled_departure_utc >= :after_utc
order by t.scheduled_departure_utc
limit 20;

-- Example
select
    t.id,
    t.scheduled_departure_utc,
    t.status
from trips t
where t.route_id = 'LINE-M2'
  and t.scheduled_departure_utc >= '2026-08-28 08:30:00+00'
order by t.scheduled_departure_utc
limit 20;

-- Query 2: ordered route stops
-- TODO: join route_stops to stops and order by stop_sequence (show the ordered stops belonging to a route)
select
    rs.route_id,
    rs.stop_id,
    rs.stop_sequence
from route_stops rs
join stops s on s.id = rs.stop_id
where rs.route_id = :route_id
order by rs.stop_sequence;

-- Example
select
    rs.route_id,
    rs.stop_id,
    rs.stop_sequence
from route_stops rs
join stops s on s.id = rs.stop_id
where rs.route_id = 'LINE-M2'
order by rs.stop_sequence;

-- Query 3: routes and trip count, including routes with zero trips
-- TODO: preserve routes with no matching trips for the supplied service date (show all routes and the number of scheduled trips on a supplied service date, including routes with no trips)
select
    r.id,
    count(t.id) AS number_of_trips
from routes r
left join trips t
    on t.route_id = r.id
    and t.service_date = :service_date
group by r.id;

-- Example
select
    r.id,
    count(t.id) AS number_of_trips
from routes r
left join trips t
    on t.route_id = r.id
    and t.service_date = '2026-08-28'
group by r.id;