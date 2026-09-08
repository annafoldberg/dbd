create table operators (
    id text primary key,
    name text not null
);

create table routes (
    id text primary key,
    operator_id text not null references operators(id),
    city_id text not null,
    mode text not null,
    short_name text not null
);

create table stops (
    id text primary key,
    city_id text not null,
    name text not null
);

create table route_stops (
    primary key (route_id, stop_sequence),
    route_id text not null references routes(id),
    stop_id text not null references stops(id),
    stop_sequence integer not null,
    -- TODO: choose and add the primary key.
    -- Explain whether a stop may occur more than once on the same route.
    -- A stop may occur more than once on the same route. This can be either if a route passes by the same stop more than once, or if a route should be understood in the way that it's from a beginning station which is also the end station (this would make sense considering trips only references one route, not multiple, as it's currently set up, and I would understand a trip as being a full round-trip).
    -- The way route_stops is set up, and its primary key being
    -- (route_id, stop_sequence), it allows only one stop at a time along the route
    -- if the primary key was (route_id, stop_id) as would be the usual
    -- choice, this would constrain the table to only have a stop once
    -- along the same route.
    constraint route_stops_sequence_positive check (stop_sequence > 0)
);

create table trips (
    id text primary key,
    route_id text not null references routes(id),
    service_date date not null,
    scheduled_departure_utc timestamptz not null,
    status text not null
);
